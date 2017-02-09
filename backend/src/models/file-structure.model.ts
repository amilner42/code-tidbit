/// Module for encapsulating helper functions for the FileStructure model.

import { objectMap } from '../util';
import Bluebird from "bluebird";


/**
* A file structure, same structure as the frontend. We parameterize accross
* 3 levels of metadata to keep it re-usable.
*/
export interface FileStructure<FileStructureMetadata, FolderMetadata, FileMetadata> {
  rootFolder: Folder<FolderMetadata, FileMetadata>;
  fsMetadata: FileStructureMetadata;
};

/**
* A file as seen on the frontend.
*/
export interface File<FileMetadata> {
  content: string;
  fileMetadata: FileMetadata;
};

/**
* A folder as seen on the frontend.
*/
export interface Folder<FolderMetadata, FileMetadata> {
  files: { [fileName: string]: File<FileMetadata> };
  folders: { [folderName: string]: Folder<FolderMetadata, FileMetadata> };
  folderMetadata: FolderMetadata;
};


/**
* Maps async functions across all 3 levels of metadata, rejects if any promise
* rejects, othewise succeeds.
*
* Returns a new copy, does not modify existing FS.
*
* Doesn't do null-checks, expects a valid FS.
*/
export const metaMap = <a, b, c, a1, b1, c1>
  (aFunc: (a: a) => Promise<a1>,
  bFunc: (b: b) => Promise<b1>,
  cFunc: (c: c) => Promise<c1>,
  fileStructure: FileStructure<a, b, c>)
  : Promise<FileStructure<a1, b1, c1>> => {

  // Map folder (and children) metadata.
  const applyFolder = (folder: Folder<b, c>): Promise<Folder<b1, c1>> => {
    return new Promise<Folder<b1, c1>>((resolve, reject) => {
      Promise.all([
        bFunc(folder.folderMetadata),
        Bluebird.props(objectMap(folder.files, applyFile)),
        Bluebird.props(objectMap(folder.folders, applyFolder))
      ])
      .then(([newFolderMetadata, newFiles, newFolders ]) => {
        resolve({
          files: newFiles,
          folders: newFolders,
          folderMetadata: newFolderMetadata
        });
      })
      .catch(reject);
    });
  };

  // Map file metadata.
  const applyFile = (file: File<c>): Promise<File<c1>> => {
    return new Promise<File<c1>>((resolve, reject) => {
      cFunc(file.fileMetadata)
      .then((newFileMetadata) => {
        resolve({
          content: file.content,
          fileMetadata: newFileMetadata
        });
      })
      .catch(reject);
    });
  };

  return new Promise<FileStructure<a1, b1, c1>>((resolve, reject) => {
    Promise.all([
      aFunc(fileStructure.fsMetadata),
      applyFolder(fileStructure.rootFolder)
    ])
    .then(([newFSMetadata, newRootFolder]) => {
      resolve({
        rootFolder: newRootFolder,
        fsMetadata: newFSMetadata
      });
    })
    .catch(reject);
  });
};

/**
 * When putting an fs into the db, we swap all '.' with '*', when taking the fs
 * out of the db, we do the reverse. MongoDB cannot have periods in key names.
 * This returns a new file structure and does not modify the old one.
 */
export const swapPeriodsWithStarsForFS = <a,b,c>(goingIntoDB: boolean, fs: FileStructure<a,b,c>): FileStructure<a,b,c> => {

  // Performs swap of '.' and '*' depending on whether we are going in or out
  // out of the db.
  const getNewKey = (oldKey: string): string => {
    return (goingIntoDB ? oldKey.replace(/\./g, "*") : oldKey.replace(/\*/g, "."));
  };

  const applyRenameOnFolder = (folder: Folder<b,c>): Folder<b,c> => {
    return {
      files: (() => {
        const newFiles = {};

        for(let key in folder.files) {
          const newKey = getNewKey(key);
          newFiles[newKey] = folder.files[key];
        }
        return newFiles;
      })(),
      folders: (() => {
        const newFolders = {};

        for(let key in folder.folders) {
          const newKey = getNewKey(key);
          newFolders[newKey] = applyRenameOnFolder(folder.folders[key]);
        }

        return newFolders;
      })(),
      folderMetadata: folder.folderMetadata
    }
  }

  return {
    fsMetadata: fs.fsMetadata,
    rootFolder: applyRenameOnFolder(fs.rootFolder)
  }
};
