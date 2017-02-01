module Models.FileStructure exposing (..)

import Dict
import Html exposing (div, text)
import Html.Attributes exposing (class, hidden)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


-- TODO Test and publish as solution to handling files/folders.
-- TODO metamap


{-| For clarity.
-}
type alias Content =
    String


{-| For clarity.
-}
type alias Name =
    String


{-| For clarity.

NOTE: Paths may optionally start with a slash. All paths should be absolute.
-}
type alias Path =
    String


{-| A filestructure is where all the code and metadata is stored.

NOTE: Metadata can be placed at the top level, on folders, and on files.
-}
type FileStructure fileStructureMetadata folderMetadata fileMetadata
    = FileStructure (Folder folderMetadata fileMetadata) fileStructureMetadata


{-| A file with metadata.
-}
type File metadata
    = File Content metadata


{-| A folder with metadata.
-}
type Folder folderMetadata fileMetadata
    = Folder (Dict.Dict Name (File fileMetadata)) (Dict.Dict Name (Folder folderMetadata fileMetadata)) folderMetadata


{-| Creates an empty fs.
-}
emptyFS : a -> b -> FileStructure a b c
emptyFS fsMetadata folderMetadata =
    FileStructure (Folder Dict.empty Dict.empty folderMetadata) fsMetadata


{-| Returns true if the FileStructure has no sub-folders/files.
-}
isEmpty : FileStructure a b c -> Bool
isEmpty (FileStructure (Folder files subFolders metadata) fsMetaData) =
    Dict.isEmpty subFolders && Dict.isEmpty files


{-| Checks if an entire fs is oepn, requires fsMetadata have `openFS`.
-}
isOpen : FileStructure { a | openFS : Bool } b c -> Bool
isOpen (FileStructure _ { openFS }) =
    openFS


{-| Similar to a `map`, but does not allow to change the type, only the value.

It will run the map on the folders fist, then on the files, then on the
fsMetadata. The ordering of the folder mapping and file mapping is important
because folderMap can also change files.

For the folder mapping itself, it will run it from top to bottom, first mapping
a node and then mapping on all it's posssibly modified children. Because it
first changes itself then runs on it's possibly new/altered children, we can't
change the type itself or it would change the type of it's children and then
the recursive function would be typed incorrectly. Use this function when you
want to modify the structures values but not the structure itself
(of the metadata, hence a b and c are fixed).
-}
valueMap :
    FileStructure a b c
    -> (Name -> Path -> Folder b c -> Folder b c)
    -> (Name -> Path -> File c -> File c)
    -> (a -> a)
    -> FileStructure a b c
valueMap ((FileStructure rootFolder metadata) as fs) folderFunc fileFunc fsFunc =
    let
        {- Map over the folders, first map over the current fodlder node then
           map over it's possibly new/altered subfolders.
        -}
        folderMap : FileStructure a b c -> FileStructure a b c
        folderMap (FileStructure rootFolder metadata) =
            let
                mapOverFolderTree name absolutePath folder =
                    folderFunc name absolutePath folder
                        |> (\(Folder files folders folderMetadata) ->
                                Folder
                                    files
                                    (Dict.map
                                        (\subFolderName subFolder ->
                                            mapOverFolderTree
                                                subFolderName
                                                (absolutePath ++ subFolderName ++ "/")
                                                subFolder
                                        )
                                        folders
                                    )
                                    folderMetadata
                           )
            in
                FileStructure
                    (mapOverFolderTree "" "/" rootFolder)
                    metadata

        {- Map over all the files. -}
        fileMap : FileStructure a b c -> FileStructure a b c
        fileMap (FileStructure rootFolder fsMetadata) =
            let
                mapOverFileTree name absolutePath (Folder files folders folderMetadata) =
                    Folder
                        (Dict.map
                            (\fileName file ->
                                fileFunc fileName (absolutePath ++ fileName) file
                            )
                            files
                        )
                        (Dict.map
                            (\subFolderName subFolder ->
                                mapOverFileTree subFolderName (absolutePath ++ subFolderName ++ "/") subFolder
                            )
                            folders
                        )
                        folderMetadata
            in
                FileStructure
                    (mapOverFileTree "" "/" rootFolder)
                    metadata

        fsMap : FileStructure a b c -> FileStructure a b c
        fsMap (FileStructure rootFolder fsMetadata) =
            FileStructure
                rootFolder
                (fsFunc fsMetadata)
    in
        fs
            |> folderMap
            |> fileMap
            |> fsMap


{-| Toggles whether the FS is open.
-}
toggleFS : FileStructure { a | openFS : Bool } b c -> FileStructure { a | openFS : Bool } b c
toggleFS (FileStructure tree fsMetadata) =
    FileStructure
        tree
        { fsMetadata
            | openFS = (not fsMetadata.openFS)
        }


{-| Toggles whether a specific folder is expanded or not.
-}
toggleFSFolder : Path -> FileStructure a { b | isExpanded : Bool } c -> FileStructure a { b | isExpanded : Bool } c
toggleFSFolder absolutePath fs =
    updateFolder
        absolutePath
        (\(Folder files folders folderMetadata) ->
            Folder
                files
                folders
                { folderMetadata
                    | isExpanded = not folderMetadata.isExpanded
                }
        )
        fs


{-| Drops the first char from a string if it starts with a slash.
-}
dropOptionalLeftSlash : String -> String
dropOptionalLeftSlash someString =
    if String.startsWith "/" someString then
        String.dropLeft 1 someString
    else
        someString


{-| Drops the last char from a string if it ends with a slash.
-}
dropOptionalRightSlash : String -> String
dropOptionalRightSlash someString =
    if String.endsWith "/" someString then
        String.dropRight 1 someString
    else
        someString


{-| Gets a specific folder from the tree if it exists in the tree, otherwise
`Nothing`.
-}
getFolder : FileStructure a b c -> Path -> Maybe (Folder b c)
getFolder (FileStructure rootFolder metadata) absolutePath =
    let
        followPath ((Folder files folders metadata) as folder) listPath =
            case listPath of
                [] ->
                    Just folder

                a :: rest ->
                    Dict.get a folders
                        |> Maybe.andThen ((flip followPath) rest)
    in
        if absolutePath == "/" then
            Just rootFolder
        else
            absolutePath
                |> dropOptionalLeftSlash
                |> dropOptionalRightSlash
                |> String.split "/"
                |> followPath rootFolder


{-| Gets a specific file from the tree if it exists in the tree, otherwise
`Nothing`.
-}
getFile : FileStructure a b c -> Path -> Maybe (File c)
getFile (FileStructure rootFolder metadata) absolutePath =
    let
        followPath (Folder files folders metadata) listPath =
            case listPath of
                -- File must have a name.
                [] ->
                    Nothing

                [ fileName ] ->
                    Dict.get fileName files

                folderName :: restOfPath ->
                    Dict.get folderName folders
                        |> Maybe.andThen ((flip followPath) restOfPath)
    in
        absolutePath
            |> dropOptionalLeftSlash
            |> String.split "/"
            |> followPath rootFolder


{-| Updates a specific file if it exists.
-}
updateFile : Path -> (File c -> File c) -> FileStructure a b c -> FileStructure a b c
updateFile absolutePath fileUpdater (FileStructure rootFolder metadata) =
    let
        followAndUpdate : Folder b c -> List String -> Folder b c
        followAndUpdate ((Folder files folders metadata) as folder) listPath =
            case listPath of
                -- File must have a name.
                [] ->
                    folder

                [ fileName ] ->
                    case Dict.get fileName files of
                        Nothing ->
                            folder

                        Just file ->
                            Folder
                                (Dict.insert fileName (fileUpdater file) files)
                                folders
                                metadata

                folderName :: restOfPath ->
                    case Dict.get folderName folders of
                        Nothing ->
                            folder

                        Just childFolder ->
                            Folder
                                files
                                (Dict.insert folderName
                                    (followAndUpdate childFolder restOfPath)
                                    folders
                                )
                                metadata
    in
        absolutePath
            |> dropOptionalLeftSlash
            |> String.split "/"
            |> followAndUpdate rootFolder
            |> ((flip FileStructure) metadata)


{-| Updates a specific folder if it exists.
-}
updateFolder : Path -> (Folder b c -> Folder b c) -> FileStructure a b c -> FileStructure a b c
updateFolder absolutePath folderUpdater (FileStructure rootFolder fsMetadata) =
    let
        followAndUpdate : Folder b c -> List String -> Folder b c
        followAndUpdate ((Folder files folders metadata) as folder) listPath =
            case listPath of
                [] ->
                    folder

                [ folderName ] ->
                    case Dict.get folderName folders of
                        Nothing ->
                            folder

                        Just childFolder ->
                            Folder
                                files
                                (Dict.insert
                                    folderName
                                    (folderUpdater childFolder)
                                    folders
                                )
                                metadata

                folderName :: restOfPath ->
                    case Dict.get folderName folders of
                        Nothing ->
                            folder

                        Just childFolder ->
                            Folder
                                files
                                (Dict.insert
                                    folderName
                                    (followAndUpdate childFolder restOfPath)
                                    folders
                                )
                                metadata
    in
        if absolutePath == "/" then
            FileStructure
                (folderUpdater rootFolder)
                fsMetadata
        else
            absolutePath
                |> dropOptionalLeftSlash
                |> dropOptionalRightSlash
                |> String.split "/"
                |> followAndUpdate rootFolder
                |> ((flip FileStructure) fsMetadata)


{-| The options for adding a folder.

@param forceCreateDirectories A function for creating blank directories given
                              a folderName, for force-creating directories.
@param overwriteExisting Will only overwrite an existing folder if this is set
                         to true.
-}
type alias AddFolderOptions b c =
    { forceCreateDirectories : Maybe (String -> Folder b c)
    , overwriteExisting : Bool
    }


{-| Adds a folder, refer to `AddFolderOptions` to see the options.
-}
addFolder : AddFolderOptions b c -> Path -> Folder b c -> FileStructure a b c -> FileStructure a b c
addFolder addFolderOptions absolutePath newFolder (FileStructure rootFolder fsMetadata) =
    let
        {- @param folder The current folder
           @param listPath the remaining path
        -}
        createFolder : Folder b c -> List String -> Folder b c
        createFolder ((Folder files folders folderMetadata) as folder) listPath =
            case listPath of
                [] ->
                    folder

                [ folderName ] ->
                    if (Dict.member folderName folders) && not addFolderOptions.overwriteExisting then
                        folder
                    else
                        Folder
                            files
                            (Dict.insert
                                folderName
                                newFolder
                                folders
                            )
                            folderMetadata

                folderName :: restOfPath ->
                    case Dict.get folderName folders of
                        Nothing ->
                            case addFolderOptions.forceCreateDirectories of
                                Nothing ->
                                    folder

                                Just createEmptyFolder ->
                                    let
                                        newForceCreatedFolder =
                                            createFolder (createEmptyFolder folderName) restOfPath
                                    in
                                        Folder
                                            files
                                            (Dict.insert folderName newForceCreatedFolder folders)
                                            folderMetadata

                        Just aFolder ->
                            Folder
                                files
                                (Dict.insert
                                    folderName
                                    (createFolder aFolder restOfPath)
                                    folders
                                )
                                folderMetadata
    in
        absolutePath
            |> dropOptionalLeftSlash
            |> dropOptionalRightSlash
            |> String.split "/"
            |> createFolder rootFolder
            |> ((flip FileStructure) fsMetadata)


{-| The options for adding a file.

@param forceCreateDirectories Will only create directories along the way if they
                              don't already exist if set to true.
@param overwriteExisting Will only replace existing files if this is set to
                         true.
-}
type alias AddFileOptions b c =
    { overwriteExisting : Bool
    , forceCreateDirectories : Maybe (String -> Folder b c)
    }


{-| Adds a file, refer to `AddFileOptions` to see options.
-}
addFile : AddFileOptions b c -> Path -> File c -> FileStructure a b c -> FileStructure a b c
addFile addFileOptions absolutePath newFile (FileStructure rootFolder fsMetadata) =
    let
        createFile ((Folder files folders folderMetadata) as folder) listPath =
            case listPath of
                [] ->
                    folder

                [ fileName ] ->
                    if Dict.member fileName files && not addFileOptions.overwriteExisting then
                        folder
                    else
                        Folder
                            (Dict.insert fileName newFile files)
                            folders
                            folderMetadata

                folderName :: restOfPath ->
                    case Dict.get folderName folders of
                        Nothing ->
                            case addFileOptions.forceCreateDirectories of
                                Nothing ->
                                    folder

                                Just createEmptyFolder ->
                                    let
                                        newForceCreatedFolder =
                                            createFile (createEmptyFolder folderName) restOfPath
                                    in
                                        Folder
                                            files
                                            (Dict.insert folderName newForceCreatedFolder folders)
                                            folderMetadata

                        Just aFolder ->
                            Folder
                                files
                                (Dict.insert
                                    folderName
                                    (createFile aFolder restOfPath)
                                    folders
                                )
                                folderMetadata
    in
        absolutePath
            |> dropOptionalLeftSlash
            |> String.split "/"
            |> createFile rootFolder
            |> ((flip FileStructure) fsMetadata)


{-| All the config for rendering a file structure.
-}
type alias RenderConfig b c msg =
    { fileStructureClassName : String
    , folderClassName : String
    , subContentBoxClassName : String
    , subFoldersBoxClassName : String
    , subFilesBoxClassName : String
    , renderFile : Name -> Path -> c -> Html.Html msg
    , renderFolder : Name -> Path -> b -> Html.Html msg
    , expandFolderIf : b -> Bool
    }


{-| For rendering a FileStructure.
-}
render :
    RenderConfig b c msg
    -> FileStructure a b c
    -> Html.Html msg
render renderConfig (FileStructure rootFolder fsMetadata) =
    let
        renderFolder : Name -> Path -> Folder b c -> Html.Html msg
        renderFolder name absolutePath (Folder files folders folderMetadata) =
            div
                [ class renderConfig.folderClassName ]
                [ renderConfig.renderFolder name absolutePath folderMetadata
                , div
                    [ class renderConfig.subContentBoxClassName
                    , hidden <| not <| renderConfig.expandFolderIf folderMetadata
                    ]
                    [ div
                        [ class renderConfig.subFoldersBoxClassName ]
                        (List.map Tuple.second <|
                            Dict.toList <|
                                Dict.map
                                    (\folderName folder ->
                                        renderFolder folderName (absolutePath ++ folderName ++ "/") folder
                                    )
                                    folders
                        )
                    , div
                        [ class renderConfig.subFilesBoxClassName ]
                        (List.map Tuple.second <|
                            Dict.toList <|
                                Dict.map
                                    (\fileName (File content fileMetadata) ->
                                        renderConfig.renderFile fileName (absolutePath ++ fileName) fileMetadata
                                    )
                                    files
                        )
                    ]
                ]
    in
        div
            [ class renderConfig.fileStructureClassName ]
            [ (renderFolder "" "/" rootFolder) ]


{-| Encodes the FS given the metadata encoders.
-}
encodeFS :
    FileStructure fsMetadata folderMetadata fileMetadata
    -> Decode.Decoder fsMetadata
    -> Decode.Decoder folderMetadata
    -> Decode.Decoder fileMetadata
    -> Encode.Value
encodeFS (FileStructure rootFolder metadata) fsMetadataDecoder folderMetadataDecoder fileMetadataDecoder =
    Encode.string "TODO"



-- TODO decodeFS
