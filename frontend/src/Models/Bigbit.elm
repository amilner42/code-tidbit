module Models.Bigbit exposing (..)

import Array
import Char
import DefaultServices.Util as Util
import Dict
import Elements.Editor as Editor
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.HighlightedComment as HighlightedComment
import Elements.FileStructure as FS
import Models.Range as Range
import Models.Route as Route


{-| A Bigbit as seen in the database, with a few extra fields thrown in the FS
to make it easier to render.
-}
type alias Bigbit =
    { name : String
    , description : String
    , tags : List String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure { openFS : Bool } { isExpanded : Bool } { language : Editor.Language }
    , highlightedComments : Array.Array BigbitHighlightedCommentForPublication
    , author : String
    , id : String
    }


{-| Bigbit encoder.
-}
bigbitEncoder : Bigbit -> Encode.Value
bigbitEncoder bigbit =
    let
        encodeFS fs =
            FS.encodeFS
                (\fsMetadata ->
                    Encode.object
                        [ ( "openFS", Encode.bool fsMetadata.openFS ) ]
                )
                (\folderMetadata ->
                    Encode.object
                        [ ( "isExpanded", Encode.bool folderMetadata.isExpanded ) ]
                )
                (\fileMetadata ->
                    Encode.object
                        [ ( "language", Editor.languageCacheEncoder fileMetadata.language ) ]
                )
                fs
    in
        Encode.object
            [ ( "name", Encode.string bigbit.name )
            , ( "description", Encode.string bigbit.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbit.tags )
            , ( "introduction", Encode.string bigbit.introduction )
            , ( "conclusion", Encode.string bigbit.conclusion )
            , ( "fs", encodeFS bigbit.fs )
            , ( "highlightedComments"
              , Encode.array <|
                    Array.map
                        bigbitHighlightedCommentForPublicationCacheEncoder
                        bigbit.highlightedComments
              )
            , ( "author", Encode.string bigbit.author )
            , ( "id", Encode.string bigbit.id )
            ]


{-| Bigbit decoder.
-}
bigbitDecoder : Decode.Decoder Bigbit
bigbitDecoder =
    let
        decodeFS =
            FS.decodeFS
                (decode (\isOpen -> { openFS = isOpen })
                    |> optional "openFS" Decode.bool False
                )
                (decode (\isExpanded -> { isExpanded = isExpanded })
                    |> optional "isExpanded" Decode.bool True
                )
                (decode BigbitCreateDataFileMetadata
                    |> required "language" Editor.languageCacheDecoder
                )
    in
        decode Bigbit
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" decodeFS
            |> required "highlightedComments" (Decode.array bigbitHighlightedCommentForPublicationCacheDecoder)
            |> required "author" Decode.string
            |> required "id" Decode.string


{-| Basic union to keep track of the current state of the action buttons in
the file structure.
-}
type FSActionButtonState
    = AddingFolder
    | AddingFile
    | RemovingFolder
    | RemovingFile


{-| FSActionButtonState `cacheEncoder`.
-}
fsActionButtonStateCacheEncoder : FSActionButtonState -> Encode.Value
fsActionButtonStateCacheEncoder =
    toString >> Encode.string


{-| FSActionButtonState `cacheDecoder`.
-}
fsActionButtonStateCacheDecoder : Decode.Decoder FSActionButtonState
fsActionButtonStateCacheDecoder =
    let
        fromStringDecoder encodedActionState =
            case encodedActionState of
                "AddingFile" ->
                    Decode.succeed AddingFile

                "AddingFolder" ->
                    Decode.succeed AddingFolder

                "RemovingFile" ->
                    Decode.succeed RemovingFile

                "RemovingFolder" ->
                    Decode.succeed RemovingFolder

                _ ->
                    Decode.fail <| "Not a valid encoded action state: " ++ encodedActionState
    in
        Decode.string
            |> Decode.andThen fromStringDecoder


{-| A full bigbit ready for publication.
-}
type alias BigbitForPublication =
    { name : String
    , description : String
    , tags : List String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure () () { language : Editor.Language }
    , highlightedComments : List BigbitHighlightedCommentForPublication
    }


{-| BigbitForPublication `encoder`.
-}
bigbitForPublicationEncoder : BigbitForPublication -> Encode.Value
bigbitForPublicationEncoder bigbit =
    let
        encodeFS fs =
            FS.encodeFS
                (always <| Encode.object [])
                (always <| Encode.object [])
                (\fileMetadata ->
                    Encode.object
                        [ ( "language", Editor.languageCacheEncoder fileMetadata.language ) ]
                )
                fs
    in
        Encode.object
            [ ( "name", Encode.string bigbit.name )
            , ( "description", Encode.string bigbit.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbit.tags )
            , ( "introduction", Encode.string bigbit.introduction )
            , ( "conclusion", Encode.string bigbit.conclusion )
            , ( "fs", encodeFS bigbit.fs )
            , ( "highlightedComments"
              , Encode.list <|
                    List.map
                        bigbitHighlightedCommentForPublicationCacheEncoder
                        bigbit.highlightedComments
              )
            ]


{-| The metadata connected to the FS.
-}
type alias BigbitCreateDataFSMetadata =
    { activeFile : Maybe FS.Path
    , openFS : Bool
    , actionButtonState : Maybe FSActionButtonState
    , actionButtonInput : String
    , actionButtonSubmitConfirmed : Bool
    }


{-| The metadata connected to every folder in the FS.
-}
type alias BigbitCreateDataFolderMetadata =
    { isExpanded : Bool
    }


{-| The metadata connected to every file in the FS.
-}
type alias BigbitCreateDataFileMetadata =
    { language : Editor.Language
    }


{-| Bigbit HighlightedComments for publication.
-}
type alias BigbitHighlightedCommentForPublication =
    { comment : String
    , range : Range.Range
    , file : FS.Path
    }


{-| BigbitHighlightedCommentForPublication `cacheEncoder`.
-}
bigbitHighlightedCommentForPublicationCacheEncoder : BigbitHighlightedCommentForPublication -> Encode.Value
bigbitHighlightedCommentForPublicationCacheEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "range", Range.rangeCacheEncoder hc.range )
        , ( "file", Encode.string hc.file )
        ]


{-| BigbitHighlightedCommentForPublication `cacheDecoder`.
-}
bigbitHighlightedCommentForPublicationCacheDecoder : Decode.Decoder BigbitHighlightedCommentForPublication
bigbitHighlightedCommentForPublicationCacheDecoder =
    decode BigbitHighlightedCommentForPublication
        |> required "comment" Decode.string
        |> required "range" Range.rangeCacheDecoder
        |> required "file" Decode.string


{-| The highlighted comments on bigbits are different than regular highlighted
comments (`Models/HighlightedComment`) because they also need to point to a
file.
-}
type alias BigbitHighlightedCommentForCreate =
    { comment : String
    , fileAndRange : Maybe FileAndRange
    }


{-| A file and a range, used in bigbit highlighted comments.
-}
type alias FileAndRange =
    { range : Maybe Range.Range
    , file : FS.Path
    }


{-| Creates an empty highlighted comment.
-}
emptyBigbitHighlightCommentForCreate : BigbitHighlightedCommentForCreate
emptyBigbitHighlightCommentForCreate =
    { comment = ""
    , fileAndRange = Nothing
    }


{-| BigbitHighlightedCommentForCreate `cacheEncoder`.
-}
bigbitHighlightedCommentForCreateCacheEncoder : BigbitHighlightedCommentForCreate -> Encode.Value
bigbitHighlightedCommentForCreateCacheEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "fileAndRange"
          , Util.justValueOrNull
                (\fileAndRange ->
                    Encode.object
                        [ ( "range", Util.justValueOrNull Range.rangeCacheEncoder fileAndRange.range )
                        , ( "file", Encode.string fileAndRange.file )
                        ]
                )
                hc.fileAndRange
          )
        ]


{-| BigbitHighlightedCommentForCreate `cacheDecoder`.
-}
bigbitHighlightedCommentForCreateCacheDecoder : Decode.Decoder BigbitHighlightedCommentForCreate
bigbitHighlightedCommentForCreateCacheDecoder =
    let
        decodeFileAndRange =
            Decode.maybe
                (decode FileAndRange
                    |> required "range" (Decode.maybe Range.rangeCacheDecoder)
                    |> required "file" Decode.string
                )
    in
        decode BigbitHighlightedCommentForCreate
            |> required "comment" Decode.string
            |> required "fileAndRange" decodeFileAndRange


{-| The data being stored for a bigbit being created.
-}
type alias BigbitCreateData =
    { name : String
    , description : String
    , tags : List String
    , tagInput : String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure BigbitCreateDataFSMetadata BigbitCreateDataFolderMetadata BigbitCreateDataFileMetadata
    , highlightedComments : Array.Array BigbitHighlightedCommentForCreate
    }


{-| BigbitCreateData `cacheEncoder`.
-}
bigbitCreateDataCacheEncoder : BigbitCreateData -> Encode.Value
bigbitCreateDataCacheEncoder bigbitCreateData =
    let
        encodeFS =
            FS.encodeFS
                (\fsMetadata ->
                    Encode.object
                        [ ( "activeFile", Util.justValueOrNull Encode.string fsMetadata.activeFile )
                        , ( "openFS", Encode.bool fsMetadata.openFS )
                        , ( "actionButtonState", Util.justValueOrNull fsActionButtonStateCacheEncoder fsMetadata.actionButtonState )
                        , ( "actionButtonInput", Encode.string fsMetadata.actionButtonInput )
                        , ( "actionButtonSubmitConfirmed", Encode.bool fsMetadata.actionButtonSubmitConfirmed )
                        ]
                )
                (\folderMetadata ->
                    Encode.object
                        [ ( "isExpanded", Encode.bool folderMetadata.isExpanded ) ]
                )
                (\fileMetadata ->
                    Encode.object
                        [ ( "language", Editor.languageCacheEncoder fileMetadata.language ) ]
                )
    in
        Encode.object
            [ ( "name", Encode.string bigbitCreateData.name )
            , ( "description", Encode.string bigbitCreateData.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbitCreateData.tags )
            , ( "tagInput", Encode.string bigbitCreateData.tagInput )
            , ( "introduction", Encode.string bigbitCreateData.introduction )
            , ( "conclusion", Encode.string bigbitCreateData.conclusion )
            , ( "fs", encodeFS bigbitCreateData.fs )
            , ( "highlightedComments", Encode.array <| Array.map bigbitHighlightedCommentForCreateCacheEncoder bigbitCreateData.highlightedComments )
            ]


{-| BigbitCreateData `cacheDecoder`.
-}
bigbitCreateDataCacheDecoder : Decode.Decoder BigbitCreateData
bigbitCreateDataCacheDecoder =
    let
        decodeFS =
            FS.decodeFS
                (decode BigbitCreateDataFSMetadata
                    |> required "activeFile" (Decode.maybe Decode.string)
                    |> required "openFS" Decode.bool
                    |> required "actionButtonState" (Decode.maybe fsActionButtonStateCacheDecoder)
                    |> required "actionButtonInput" Decode.string
                    |> required "actionButtonSubmitConfirmed" Decode.bool
                )
                (decode BigbitCreateDataFolderMetadata
                    |> required "isExpanded" Decode.bool
                )
                (decode BigbitCreateDataFileMetadata
                    |> required "language" Editor.languageCacheDecoder
                )
    in
        decode BigbitCreateData
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "tagInput" Decode.string
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" decodeFS
            |> required "highlightedComments" (Decode.array bigbitHighlightedCommentForCreateCacheDecoder)


{-| Possible errors with input for creating a file.
-}
type InvalidFileName
    = FileHasInvalidCharacters
    | FileAlreadyExists
    | FileIsEmpty
    | FileHasDoubleSlash
    | FileEndsInSlash
    | FileHasInvalidExtension
    | FileLanguageIsAmbiguous (List Editor.Language)


{-| Possible errors with input for creating a folder.
-}
type InvalidFolderName
    = FolderHasInvalidCharacters
    | FolderAlreadyExists
    | FolderIsEmpty
    | FolderHasDoubleSlash


{-| Possible erros with input for removing a file.
-}
type InvalidRemoveFileName
    = RemoveFileIsEmpty
    | RemoveFileDoesNotExist


{-| Possible erros with input for removing a folder.
-}
type InvalidRemoveFolderName
    = RemoveFolderIsEmpty
    | RemoveFolderIsRootFolder
    | RemoveFolderDoesNotExist


{-| Checks if the path has invalid characters.

NOTE: Only the following are valid characters: a-Z 1-9 - _ . /

NOTE: We restrict the characters because:
  - It'll keep it cleaner, I don't want funky ascii chars.
  - We'll need to encode them for the url params, prevent weird bugs.
-}
pathHasInvalidChars : FS.Path -> Bool
pathHasInvalidChars =
    String.toList
        >> List.all
            (\char ->
                Char.isDigit char
                    || Char.isUpper char
                    || Char.isLower char
                    || (List.member char [ '_', '-', '.', '/' ])
            )
        >> not


{-| Checks if the path has any double slashes ("//").
-}
pathHasDoubleSlash : FS.Path -> Bool
pathHasDoubleSlash =
    String.contains "//"


{-| Checks if the path is empty.
-}
pathIsEmpty : FS.Path -> Bool
pathIsEmpty =
    String.isEmpty


{-| Checks if the path ends in a slash.
-}
pathEndsInSlash : FS.Path -> Bool
pathEndsInSlash =
    String.endsWith "/"


{-| Checks that the folder path is valid.
-}
isValidAddFolderInput : FS.Path -> FS.FileStructure a b c -> Result InvalidFolderName ()
isValidAddFolderInput absolutePath fs =
    if pathIsEmpty absolutePath then
        Result.Err FolderIsEmpty
    else if pathHasDoubleSlash absolutePath then
        Result.Err FolderHasDoubleSlash
    else if pathHasInvalidChars absolutePath then
        Result.Err FolderHasInvalidCharacters
    else if FS.hasFolder absolutePath fs then
        Result.Err FolderAlreadyExists
    else
        Result.Ok ()


{-| Checks that a file path is valid and returns it's language.
-}
isValidAddFileInput : FS.Path -> FS.FileStructure a b c -> Result InvalidFileName Editor.Language
isValidAddFileInput absolutePath fs =
    if pathIsEmpty absolutePath then
        Result.Err FileIsEmpty
    else if pathHasDoubleSlash absolutePath then
        Result.Err FileHasDoubleSlash
    else if pathHasInvalidChars absolutePath then
        Result.Err FileHasInvalidCharacters
    else if pathEndsInSlash absolutePath then
        Result.Err FileEndsInSlash
    else if FS.hasFile absolutePath fs then
        Result.Err FileAlreadyExists
    else
        String.split "/" absolutePath
            |> Util.lastElem
            |> Maybe.map Editor.languagesFromFileName
            |> Maybe.withDefault []
            |> (\listOfLanguages ->
                    case listOfLanguages of
                        [] ->
                            Result.Err FileHasInvalidExtension

                        [ language ] ->
                            Result.Ok language

                        a ->
                            Result.Err <| FileLanguageIsAmbiguous a
               )


{-| Checks that a remove-file-path is valid.
-}
isValidRemoveFileInput : FS.Path -> FS.FileStructure a b c -> Result InvalidRemoveFileName ()
isValidRemoveFileInput absolutePath fs =
    if pathIsEmpty absolutePath then
        Result.Err RemoveFileIsEmpty
    else if not <| FS.hasFile absolutePath fs then
        Result.Err RemoveFileDoesNotExist
    else
        Result.Ok ()


{-| Checks that a remove-folder-path is valid.
-}
isValidRemoveFolderInput : FS.Path -> FS.FileStructure a b c -> Result InvalidRemoveFolderName ()
isValidRemoveFolderInput absolutePath fs =
    if pathIsEmpty absolutePath then
        Result.Err RemoveFolderIsEmpty
    else if absolutePath == "/" then
        Result.Err RemoveFolderIsRootFolder
    else if not <| FS.hasFolder absolutePath fs then
        Result.Err RemoveFolderDoesNotExist
    else
        Result.Ok ()


{-| If all the highlighted comments are completely filled in, will return them
in publishable form, otherwise will return Nothing.
-}
hcForCreateToPublishable : Array.Array BigbitHighlightedCommentForCreate -> Maybe (List BigbitHighlightedCommentForPublication)
hcForCreateToPublishable hcArray =
    (Array.foldr
        (\hc currentList ->
            if String.isEmpty hc.comment then
                currentList
            else
                case hc.fileAndRange of
                    Nothing ->
                        currentList

                    Just { file, range } ->
                        case range of
                            Nothing ->
                                currentList

                            Just aRange ->
                                if Range.isEmptyRange aRange then
                                    currentList
                                else
                                    { file = file
                                    , comment = hc.comment
                                    , range = aRange
                                    }
                                        :: currentList
        )
        []
        hcArray
    )
        |> (\publishableListOfHC ->
                if (List.length publishableListOfHC == Array.length hcArray) then
                    Just publishableListOfHC
                else
                    Nothing
           )


{-| Given the create data, returns BigbitForPublication if the data is
completely filled out, otherwise returns Nothing.
-}
createDataToPublicationData : BigbitCreateData -> Maybe BigbitForPublication
createDataToPublicationData createData =
    if
        (String.isEmpty createData.name)
            || (String.isEmpty createData.description)
            || (List.isEmpty createData.tags)
            || (String.isEmpty createData.conclusion)
            || (String.isEmpty createData.introduction)
    then
        Nothing
    else
        hcForCreateToPublishable createData.highlightedComments
            |> Maybe.map
                (\publishableHC ->
                    { name = createData.name
                    , description = createData.description
                    , tags = createData.tags
                    , introduction = createData.introduction
                    , conclusion = createData.conclusion
                    , fs =
                        createData.fs
                            |> FS.metaMap
                                (always ())
                                (always ())
                                (\fileMetadata ->
                                    fileMetadata
                                )
                    , highlightedComments = publishableHC
                    }
                )



-- FS helpers below (refer to examples below to use row-polymorphism).


{-| Checks if an entire fs is open.
-}
isFSOpen : FS.FileStructure { a | openFS : Bool } b c -> Bool
isFSOpen (FS.FileStructure _ { openFS }) =
    openFS


{-| Toggles whether the FS is open.
-}
toggleFS : FS.FileStructure { a | openFS : Bool } b c -> FS.FileStructure { a | openFS : Bool } b c
toggleFS (FS.FileStructure tree fsMetadata) =
    FS.FileStructure
        tree
        { fsMetadata
            | openFS = (not fsMetadata.openFS)
        }


{-| Toggles whether a specific folder is expanded or not.
-}
toggleFSFolder : FS.Path -> FS.FileStructure a { b | isExpanded : Bool } c -> FS.FileStructure a { b | isExpanded : Bool } c
toggleFSFolder absolutePath fs =
    FS.updateFolder
        absolutePath
        (\(FS.Folder files folders folderMetadata) ->
            FS.Folder
                files
                folders
                { folderMetadata
                    | isExpanded = not folderMetadata.isExpanded
                }
        )
        fs


{-| Checks equality against the current state of `actionButtonState`.
-}
fsActionStateEquals : Maybe FSActionButtonState -> FS.FileStructure { a | actionButtonState : Maybe FSActionButtonState } b c -> Bool
fsActionStateEquals maybeActionState =
    FS.getFSMetadata >> .actionButtonState >> (==) maybeActionState


{-| Creates an empty folder.
-}
defaultEmptyFolder : FS.Folder BigbitCreateDataFolderMetadata BigbitCreateDataFileMetadata
defaultEmptyFolder =
    FS.emptyFolder { isExpanded = True }


{-| Clears the action button input.
-}
clearActionButtonInput : FS.FileStructure BigbitCreateDataFSMetadata b c -> FS.FileStructure BigbitCreateDataFSMetadata b c
clearActionButtonInput =
    FS.updateFSMetadata
        (\fsMetadata ->
            { fsMetadata
                | actionButtonInput = ""
            }
        )


{-| The current active path (on create page) determined from the route.
-}
createPageCurrentActiveFile : Route.Route -> Maybe FS.Path
createPageCurrentActiveFile route =
    case route of
        Route.HomeComponentCreateBigbitCodeIntroduction maybePath ->
            maybePath

        Route.HomeComponentCreateBigbitCodeFrame _ maybePath ->
            maybePath

        Route.HomeComponentCreateBigbitCodeConclusion maybePath ->
            maybePath

        _ ->
            Nothing


{-| The current active path (on view page) determined from the route or the
current comment frame.
-}
viewPageCurrentActiveFile : Route.Route -> Bigbit -> Maybe FS.Path
viewPageCurrentActiveFile route bigbit =
    case route of
        Route.HomeComponentViewBigbitIntroduction _ maybePath ->
            maybePath

        Route.HomeComponentViewBigbitFrame _ frameNumber maybePath ->
            if Util.isNotNothing maybePath then
                maybePath
            else
                Array.get (frameNumber - 1) bigbit.highlightedComments
                    |> Maybe.map .file

        Route.HomeComponentViewBigbitConclusion _ maybePath ->
            maybePath

        _ ->
            Nothing


{-| Helper for setting the actionButtonSubmitConfirmed.
-}
setActionButtonSubmitConfirmed : Bool -> FS.FileStructure { a | actionButtonSubmitConfirmed : Bool } b c -> FS.FileStructure { a | actionButtonSubmitConfirmed : Bool } b c
setActionButtonSubmitConfirmed newConfirmValue fs =
    fs
        |> FS.updateFSMetadata
            (\fsMetadata ->
                { fsMetadata
                    | actionButtonSubmitConfirmed = newConfirmValue
                }
            )
