/// Module for encapsulating helper functions for the FileStructure model.

import { objectMap } from '../util';
import { map } from "ramda";
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
      return bFunc(folder.folderMetadata)
      .then((newFolderMetadata) => {
        return Bluebird.props(objectMap(folder.files, applyFile))
        .then((newFiles: {[key: string]: File<c1>}) => {
          return Bluebird.props(objectMap(folder.folders, applyFolder))
          .then((newFolders: {[key: string]: Folder<b1,c1>}) => {
            resolve({
              files: newFiles,
              folders: newFolders,
              folderMetadata: newFolderMetadata
            });
          });
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
    aFunc(fileStructure.fsMetadata)
    .then((newFSMetadata) => {
      return applyFolder(fileStructure.rootFolder)
      .then((newRootFolder) => {
        resolve({
          rootFolder: newRootFolder,
          fsMetadata: newFSMetadata
        });
      });
    })
    .catch(reject);
  });
};
