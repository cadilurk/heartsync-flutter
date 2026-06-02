import { Router } from 'express';
import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import { ObjectId } from 'mongodb';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: Number(process.env.SPACE_UPLOAD_MAX_BYTES || 100 * 1024 * 1024),
  },
  fileFilter: (_req, file, cb) => {
    if (isAllowedUploadFile(file)) {
      cb(null, true);
      return;
    }
    cb(new Error('INVALID_FILE_TYPE'));
  },
});

export default function createSpaceRouter(db, auth, ok, fail) {
  const router = Router();
  const media = db.collection('spaceMedia');
  const notes = db.collection('spaceNotes');
  const albums = db.collection('spaceAlbums');
  const relationships = db.collection('coupleRelationships');
  const profiles = db.collection('profiles');

  media.createIndex({ relationshipId: 1, createdAt: -1 }).catch(console.error);
  media.createIndex({ relationshipId: 1, albumId: 1, createdAt: -1 }).catch(console.error);
  notes.createIndex({ relationshipId: 1, createdAt: -1 }).catch(console.error);
  notes.createIndex({ relationshipId: 1, albumId: 1, createdAt: -1 }).catch(console.error);
  notes.createIndex({ mediaIds: 1 }).catch(console.error);
  albums.createIndex({ relationshipId: 1, createdAt: -1 }).catch(console.error);

  configureCloudinary();

  router.get('/space/media', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const list = await media
        .find({ relationshipId: relationship._id })
        .sort({ memoryDate: -1, createdAt: -1 })
        .toArray();

      return res.json(ok(list.map(serializeMedia)));
    } catch (error) {
      console.error('[GET /space/media] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.post('/space/media', auth, handleUpload(fail), async (req, res) => {
    try {
      if (!hasCloudinaryConfig()) {
        console.error('[POST /space/media] Missing Cloudinary environment variables.');
        const error = fail('SERVER_ERROR', 500);
        return res.status(error.status).json(error.body);
      }

      if (!req.file) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const type = inferMediaType(req.file, req.body.type);
      const memoryDate = parseDate(req.body.memoryDate) ?? new Date();
      const note = String(req.body.note || '').trim();
      const album = await validateAlbum(albums, relationship._id, req.body.albumId);
      const albumId = album?._id ?? null;
      const mediaId = new ObjectId();
      const folder = cloudinaryMediaFolder(req.user._id, album);
      const publicId = cloudinaryMediaName(req.file.originalname, mediaId);
      console.log('[POST /space/media] Uploading to Cloudinary:', {
        folder,
        publicId,
        type,
        mimetype: req.file.mimetype,
        size: req.file.size,
        relationshipId: relationship._id.toString(),
      });
      const uploadResult = await uploadToCloudinary(req.file.buffer, {
        folder,
        public_id: publicId,
        unique_filename: false,
        overwrite: false,
        resource_type: type === 'video' ? 'video' : 'image',
        context: {
          relationshipId: relationship._id.toString(),
          uploadedByUserId: req.user._id.toString(),
          mediaId: mediaId.toString(),
        },
      });

      const now = new Date();
      const item = {
        _id: mediaId,
        relationshipId: relationship._id,
        albumId,
        uploadedByUserId: req.user._id,
        type,
        url: uploadResult.secure_url,
        publicId: uploadResult.public_id,
        resourceType: uploadResult.resource_type,
        thumbnailUrl: buildThumbnailUrl(uploadResult, type),
        note,
        memoryDate,
        createdAt: now,
        updatedAt: now,
      };

      const result = await media.insertOne(item);
      console.log('[POST /space/media] Uploaded:', {
        publicId: item.publicId,
        resourceType: item.resourceType,
        mediaId: result.insertedId.toString(),
      });

      if (note) {
        await notes.insertOne({
          relationshipId: relationship._id,
          albumId,
          createdByUserId: req.user._id,
          title: titleFromNote(note),
          content: note,
          mediaIds: [mediaId],
          memoryDate,
          createdAt: now,
          updatedAt: now,
        });
      }

      return res.json(ok(serializeMedia(item)));
    } catch (error) {
      console.error('[POST /space/media] Error:', error);
      const serverError = error.message === 'INVALID_FILE_TYPE'
        ? fail('INVALID_INPUT')
        : fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.delete('/space/media/:id', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const mediaId = toObjectId(req.params.id);
      if (!mediaId) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const item = await media.findOne({ _id: mediaId, relationshipId: relationship._id });
      if (!item) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      if (item.publicId) {
        await cloudinary.uploader.destroy(item.publicId, {
          resource_type: item.resourceType || (item.type === 'video' ? 'video' : 'image'),
        });
      }

      await media.deleteOne({ _id: item._id });
      await notes.updateMany(
        { relationshipId: relationship._id, mediaIds: item._id },
        { $pull: { mediaIds: item._id }, $set: { updatedAt: new Date() } },
      );

      return res.json(ok(true));
    } catch (error) {
      console.error('[DELETE /space/media/:id] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.put('/space/media/:id/note', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const mediaId = toObjectId(req.params.id);
      if (!mediaId) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const note = String(req.body.note || '').trim();
      const result = await media.findOneAndUpdate(
        { _id: mediaId, relationshipId: relationship._id },
        { $set: { note, updatedAt: new Date() } },
        { returnDocument: 'after' },
      );

      if (!result) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      await notes.updateMany(
        { relationshipId: relationship._id, mediaIds: mediaId },
        { $set: { content: note, title: titleFromNote(note), updatedAt: new Date() } },
      );

      return res.json(ok(serializeMedia(result)));
    } catch (error) {
      console.error('[PUT /space/media/:id/note] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.get('/space/notes', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const list = await notes
        .find({ relationshipId: relationship._id })
        .sort({ memoryDate: -1, createdAt: -1 })
        .toArray();

      return res.json(ok(list.map(serializeNote)));
    } catch (error) {
      console.error('[GET /space/notes] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.post('/space/notes', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const title = String(req.body.title || '').trim();
      const content = String(req.body.content || '').trim();
      const memoryDate = parseDate(req.body.memoryDate) ?? new Date();
      const mediaIds = normalizeMediaIds(req.body.mediaIds);
      const album = await validateAlbum(albums, relationship._id, req.body.albumId);
      const albumId = album?._id ?? null;

      if (!title && !content) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      if (mediaIds.length > 0) {
        const count = await media.countDocuments({
          _id: { $in: mediaIds },
          relationshipId: relationship._id,
        });
        if (count !== mediaIds.length) {
          const error = fail('INVALID_INPUT');
          return res.status(error.status).json(error.body);
        }
      }

      const now = new Date();
      const note = {
        relationshipId: relationship._id,
        albumId,
        createdByUserId: req.user._id,
        title: title || titleFromNote(content),
        content,
        mediaIds,
        memoryDate,
        createdAt: now,
        updatedAt: now,
      };

      const result = await notes.insertOne(note);
      note._id = result.insertedId;

      return res.json(ok(serializeNote(note)));
    } catch (error) {
      console.error('[POST /space/notes] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.put('/space/notes/:id', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const noteId = toObjectId(req.params.id);
      if (!noteId) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const title = String(req.body.title || '').trim();
      const content = String(req.body.content || '').trim();
      const memoryDate = parseDate(req.body.memoryDate);
      const update = {
        updatedAt: new Date(),
        ...(title ? { title } : {}),
        ...(content ? { content } : {}),
        ...(memoryDate ? { memoryDate } : {}),
      };

      const result = await notes.findOneAndUpdate(
        { _id: noteId, relationshipId: relationship._id },
        { $set: update },
        { returnDocument: 'after' },
      );

      if (!result) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      return res.json(ok(serializeNote(result)));
    } catch (error) {
      console.error('[PUT /space/notes/:id] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.delete('/space/notes/:id', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const noteId = toObjectId(req.params.id);
      if (!noteId) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      await notes.deleteOne({ _id: noteId, relationshipId: relationship._id });
      return res.json(ok(true));
    } catch (error) {
      console.error('[DELETE /space/notes/:id] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.get('/space/stats', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const [photoCount, videoCount, noteCount] = await Promise.all([
        media.countDocuments({ relationshipId: relationship._id, type: 'photo' }),
        media.countDocuments({ relationshipId: relationship._id, type: 'video' }),
        notes.countDocuments({ relationshipId: relationship._id }),
      ]);

      return res.json(ok({
        photoCount,
        videoCount,
        noteCount,
        momentCount: photoCount + videoCount + noteCount,
      }));
    } catch (error) {
      console.error('[GET /space/stats] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.get('/space/albums', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const list = await albums
        .find({ relationshipId: relationship._id })
        .sort({ createdAt: -1 })
        .toArray();

      return res.json(ok(list.map(serializeAlbum)));
    } catch (error) {
      console.error('[GET /space/albums] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.post('/space/albums', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const title = String(req.body.title || '').trim();
      if (!title) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const now = new Date();
      const album = {
        relationshipId: relationship._id,
        createdByUserId: req.user._id,
        title,
        description: String(req.body.description || '').trim(),
        coverMediaId: null,
        cloudinaryFolder: cloudinaryAlbumFolder(req.user._id, title),
        createdAt: now,
        updatedAt: now,
      };

      const result = await albums.insertOne(album);
      album._id = result.insertedId;
      await ensureCloudinaryFolder(album.cloudinaryFolder);

      return res.json(ok(serializeAlbum(album)));
    } catch (error) {
      console.error('[POST /space/albums] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.put('/space/albums/:id', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const albumId = toObjectId(req.params.id);
      const title = String(req.body.title || '').trim();
      if (!albumId || !title) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const album = await albums.findOne({ _id: albumId, relationshipId: relationship._id });
      if (!album) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      const nextFolder = cloudinaryAlbumFolder(req.user._id, title);
      if (album.cloudinaryFolder && album.cloudinaryFolder !== nextFolder) {
        await renameCloudinaryFolder(album.cloudinaryFolder, nextFolder);
      } else {
        await ensureCloudinaryFolder(nextFolder);
      }

      const updated = await albums.findOneAndUpdate(
        { _id: albumId, relationshipId: relationship._id },
        { $set: { title, cloudinaryFolder: nextFolder, updatedAt: new Date() } },
        { returnDocument: 'after' },
      );

      return res.json(ok(serializeAlbum(updated)));
    } catch (error) {
      console.error('[PUT /space/albums/:id] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.delete('/space/albums/:id', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const albumId = toObjectId(req.params.id);
      if (!albumId) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const album = await albums.findOne({ _id: albumId, relationshipId: relationship._id });
      if (!album) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      await Promise.all([
        media.updateMany(
          { relationshipId: relationship._id, albumId },
          { $set: { albumId: null, updatedAt: new Date() } },
        ),
        notes.updateMany(
          { relationshipId: relationship._id, albumId },
          { $set: { albumId: null, updatedAt: new Date() } },
        ),
        albums.deleteOne({ _id: albumId, relationshipId: relationship._id }),
      ]);
      await deleteCloudinaryFolderIfEmpty(album.cloudinaryFolder);

      return res.json(ok(true));
    } catch (error) {
      console.error('[DELETE /space/albums/:id] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.get('/space/memories/:id', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const noteId = toObjectId(req.params.id);
      if (!noteId) {
        const error = fail('INVALID_INPUT');
        return res.status(error.status).json(error.body);
      }

      const note = await notes.findOne({ _id: noteId, relationshipId: relationship._id });
      if (!note) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      const linkedMedia = note.mediaIds?.length
        ? await media.find({ _id: { $in: note.mediaIds }, relationshipId: relationship._id }).toArray()
        : [];

      return res.json(ok({
        note: serializeNote(note),
        media: linkedMedia.map(serializeMedia),
      }));
    } catch (error) {
      console.error('[GET /space/memories/:id] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  router.get('/space/people', auth, async (req, res) => {
    try {
      const relationship = await activeRelationshipFor(relationships, req.user._id);
      if (!relationship) {
        const error = fail('RELATIONSHIP_NOT_FOUND', 404);
        return res.status(error.status).json(error.body);
      }

      const partnerId = String(relationship.userAId) === String(req.user._id)
        ? relationship.userBId
        : relationship.userAId;
      const partnerProfile = await profiles.findOne({ userId: partnerId });

      return res.json(ok({
        relationshipId: relationship._id.toString(),
        partnerDisplayName: partnerProfile?.displayName ?? null,
      }));
    } catch (error) {
      console.error('[GET /space/people] Error:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  return router;
}

function configureCloudinary() {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
}

function hasCloudinaryConfig() {
  return Boolean(
    process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET
  );
}

function handleUpload(fail) {
  return (req, res, next) => {
    upload.single('media')(req, res, (error) => {
      if (!error) {
        next();
        return;
      }
      console.error('[POST /space/media] Upload parser error:', error.message);
      const uploadError = fail('INVALID_INPUT');
      res.status(uploadError.status).json(uploadError.body);
    });
  };
}

function uploadToCloudinary(buffer, options) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(options, (error, result) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(result);
    });
    stream.end(buffer);
  });
}

async function activeRelationshipFor(relationships, userId) {
  return relationships.findOne({
    status: 'active',
    $or: [{ userAId: userId }, { userBId: userId }],
  });
}

function serializeMedia(item) {
  return {
    id: item._id.toString(),
    relationshipId: item.relationshipId.toString(),
    albumId: item.albumId?.toString?.() ?? null,
    uploadedByUserId: item.uploadedByUserId.toString(),
    type: item.type,
    url: item.url,
    publicId: item.publicId,
    resourceType: item.resourceType,
    thumbnailUrl: item.thumbnailUrl ?? null,
    note: item.note ?? '',
    memoryDate: item.memoryDate?.toISOString?.() ?? item.memoryDate,
    createdAt: item.createdAt?.toISOString?.() ?? item.createdAt,
    updatedAt: item.updatedAt?.toISOString?.() ?? item.updatedAt,
  };
}

function serializeNote(note) {
  return {
    id: note._id.toString(),
    relationshipId: note.relationshipId.toString(),
    albumId: note.albumId?.toString?.() ?? null,
    createdByUserId: note.createdByUserId.toString(),
    title: note.title ?? '',
    content: note.content ?? '',
    mediaIds: (note.mediaIds || []).map(id => id.toString()),
    memoryDate: note.memoryDate?.toISOString?.() ?? note.memoryDate,
    createdAt: note.createdAt?.toISOString?.() ?? note.createdAt,
    updatedAt: note.updatedAt?.toISOString?.() ?? note.updatedAt,
  };
}

function serializeAlbum(album) {
  return {
    id: album._id.toString(),
    relationshipId: album.relationshipId.toString(),
    createdByUserId: album.createdByUserId.toString(),
    title: album.title ?? '',
    description: album.description ?? '',
    coverMediaId: album.coverMediaId?.toString?.() ?? null,
    cloudinaryFolder: album.cloudinaryFolder ?? null,
    createdAt: album.createdAt?.toISOString?.() ?? album.createdAt,
    updatedAt: album.updatedAt?.toISOString?.() ?? album.updatedAt,
  };
}

function buildThumbnailUrl(uploadResult, type) {
  if (type === 'photo') return uploadResult.secure_url;
  return cloudinary.url(uploadResult.public_id, {
    resource_type: 'video',
    format: 'jpg',
    transformation: [
      { width: 600, height: 600, crop: 'fill' },
    ],
    secure: true,
  });
}

function parseDate(value) {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function normalizeMediaIds(value) {
  if (!Array.isArray(value)) return [];
  return value.map(toObjectId).filter(Boolean);
}

async function validateAlbum(albums, relationshipId, value) {
  const albumId = toObjectId(value);
  if (!albumId) return null;
  return albums.findOne({ _id: albumId, relationshipId });
}

function toObjectId(value) {
  try {
    return ObjectId.isValid(value) ? new ObjectId(value) : null;
  } catch {
    return null;
  }
}

function titleFromNote(note) {
  const trimmed = String(note || '').trim();
  if (!trimmed) return 'Untitled Memory';
  return trimmed.length <= 28 ? trimmed : `${trimmed.slice(0, 28)}...`;
}

function cloudinaryMediaFolder(userId, album) {
  if (album?.cloudinaryFolder) return album.cloudinaryFolder;
  if (album?.title) return cloudinaryAlbumFolder(userId, album.title);
  return cloudinaryUserFolder(userId);
}

function cloudinaryAlbumFolder(userId, albumTitle) {
  return `${cloudinaryUserFolder(userId)}/${slugifyCloudinaryPart(albumTitle)}`;
}

function cloudinaryUserFolder(userId) {
  return slugifyCloudinaryPart(String(userId));
}

function cloudinaryMediaName(originalName, mediaId) {
  const baseName = String(originalName || '')
    .replace(/\.[^.]+$/, '')
    .trim();
  const safeName = slugifyCloudinaryPart(baseName || 'image');
  return `${safeName}-${mediaId.toString()}`;
}

function slugifyCloudinaryPart(value) {
  const slug = String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return slug || 'untitled';
}

async function ensureCloudinaryFolder(folder) {
  if (!folder || !hasCloudinaryConfig()) return;
  try {
    await cloudinary.api.create_folder(folder);
    console.log('[POST /space/albums] Created Cloudinary folder:', folder);
  } catch (error) {
    if (error?.http_code === 400 || /already exists/i.test(error?.message || '')) {
      return;
    }
    console.warn('[POST /space/albums] Could not create Cloudinary folder:', {
      folder,
      message: error.message,
    });
  }
}

async function renameCloudinaryFolder(fromFolder, toFolder) {
  if (!fromFolder || !toFolder || !hasCloudinaryConfig()) return;
  try {
    await cloudinary.api.rename_folder(fromFolder, toFolder);
    console.log('[PUT /space/albums/:id] Renamed Cloudinary folder:', { fromFolder, toFolder });
  } catch (error) {
    console.warn('[PUT /space/albums/:id] Could not rename Cloudinary folder:', {
      fromFolder,
      toFolder,
      message: error.message,
    });
    await ensureCloudinaryFolder(toFolder);
  }
}

async function deleteCloudinaryFolderIfEmpty(folder) {
  if (!folder || !hasCloudinaryConfig()) return;
  try {
    await cloudinary.api.delete_folder(folder);
    console.log('[DELETE /space/albums/:id] Deleted Cloudinary folder:', folder);
  } catch (error) {
    console.warn('[DELETE /space/albums/:id] Could not delete Cloudinary folder:', {
      folder,
      message: error.message,
    });
  }
}

function isAllowedUploadFile(file) {
  if (file.mimetype?.startsWith('image/') || file.mimetype?.startsWith('video/')) {
    return true;
  }

  const name = String(file.originalname || '').toLowerCase();
  return /\.(jpe?g|png|gif|webp|heic|heif|mp4|mov|m4v|webm|avi|mkv)$/.test(name);
}

function inferMediaType(file, requestedType) {
  if (requestedType === 'video' || file.mimetype?.startsWith('video/')) return 'video';
  if (requestedType === 'photo' || file.mimetype?.startsWith('image/')) return 'photo';

  const name = String(file.originalname || '').toLowerCase();
  if (/\.(mp4|mov|m4v|webm|avi|mkv)$/.test(name)) return 'video';
  return 'photo';
}
