module Models.Bigbit exposing (..)

import Array
import DefaultServices.ArrayExtra as ArrayExtra
import Char
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Date
import Dict
import Elements.Editor as Editor
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
    , createdAt : Date.Date
    , lastModified : Date.Date
    }


{-| Basic union to keep track of the current state of the action buttons in
the file structure.
-}
type FSActionButtonState
    = AddingFolder
    | AddingFile
    | RemovingFolder
    | RemovingFile


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
    , previewMarkdown : Bool
    }


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


{-| Creates an empty highlighted comment.
-}
emptyBigbitHighlightCommentForCreate : BigbitHighlightedCommentForCreate
emptyBigbitHighlightCommentForCreate =
    { comment = ""
    , fileAndRange = Nothing
    }


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


{-| Returns the filled-in name or `Nothing`.
-}
createDataNameFilledIn : BigbitCreateData -> Maybe String
createDataNameFilledIn =
    .name >> Util.justNonEmptyString


{-| Returns the filled-in description or `Nothing`.
-}
createDataDescriptionFilledIn : BigbitCreateData -> Maybe String
createDataDescriptionFilledIn =
    .description >> Util.justNonEmptyString


{-| Returns the filled-in tags or `Nothing`.
-}
createDataTagsFilledIn : BigbitCreateData -> Maybe (List String)
createDataTagsFilledIn =
    .tags >> Util.justNonEmptyList


{-| Returns the filled-in introduction or `Nothing`.
-}
createDataIntroductionFilledIn : BigbitCreateData -> Maybe String
createDataIntroductionFilledIn =
    .introduction >> Util.justNonEmptyString


{-| Returns the filled-in conclusion or `Nothing`.
-}
createDataConclusionFilledIn : BigbitCreateData -> Maybe String
createDataConclusionFilledIn =
    .conclusion >> Util.justNonEmptyString


{-| Returns the filled-in highlighted comments [in publication form] or
`Nothing`.
-}
createDataHighlightedCommentsFilledIn : BigbitCreateData -> Maybe (List BigbitHighlightedCommentForPublication)
createDataHighlightedCommentsFilledIn =
    .highlightedComments
        >> (Array.foldr
                (\hc currentList ->
                    if String.isEmpty hc.comment then
                        Nothing
                    else
                        case hc.fileAndRange of
                            Just { file, range } ->
                                case range of
                                    Nothing ->
                                        Nothing

                                    Just aRange ->
                                        if Range.isEmptyRange aRange then
                                            Nothing
                                        else
                                            Maybe.map
                                                ((::)
                                                    { file = file
                                                    , comment = hc.comment
                                                    , range = aRange
                                                    }
                                                )
                                                currentList

                            _ ->
                                Nothing
                )
                (Just [])
           )


{-| Returns true if all data in the code tab is filled-in.
-}
createDataCodeTabFilledIn : BigbitCreateData -> Bool
createDataCodeTabFilledIn createData =
    case
        ( createDataIntroductionFilledIn createData
        , createDataConclusionFilledIn createData
        , createDataHighlightedCommentsFilledIn createData
        )
    of
        ( Just _, Just _, Just _ ) ->
            True

        _ ->
            False


{-| Given the create data, returns BigbitForPublication if the data is
completely filled out, otherwise returns Nothing.
-}
createDataToPublicationData : BigbitCreateData -> Maybe BigbitForPublication
createDataToPublicationData createData =
    case
        ( createDataNameFilledIn createData
        , createDataDescriptionFilledIn createData
        , createDataTagsFilledIn createData
        , createDataIntroductionFilledIn createData
        , createDataConclusionFilledIn createData
        , createDataHighlightedCommentsFilledIn createData
        )
    of
        ( Just name, Just description, Just tags, Just introduction, Just conclusion, Just hc ) ->
            Just <|
                BigbitForPublication
                    name
                    description
                    tags
                    introduction
                    conclusion
                    (createData.fs
                        |> FS.metaMap (always ()) (always ()) (identity)
                    )
                    hc

        _ ->
            Nothing


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


{-| Closes the FS.
-}
closeFS : FS.FileStructure { a | openFS : Bool } b c -> FS.FileStructure { a | openFS : Bool } b c
closeFS (FS.FileStructure tree fsMetadata) =
    FS.FileStructure
        tree
        { fsMetadata
            | openFS = False
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
        Route.CreateBigbitCodeIntroductionPage maybePath ->
            maybePath

        Route.CreateBigbitCodeFramePage _ maybePath ->
            maybePath

        Route.CreateBigbitCodeConclusionPage maybePath ->
            maybePath

        _ ->
            Nothing


{-| Gets the active file (on create page) for a specific frame.
-}
createPageGetActiveFileForFrame : Int -> BigbitCreateData -> Maybe FS.Path
createPageGetActiveFileForFrame frameNumber bigbit =
    Array.get (frameNumber - 1) bigbit.highlightedComments
        |> Maybe.andThen .fileAndRange
        |> Maybe.map .file


{-| The current active path (on view page) determined from the route or the
current comment frame.
-}
viewPageCurrentActiveFile : Route.Route -> Bigbit -> Maybe FS.Path
viewPageCurrentActiveFile route bigbit =
    case route of
        Route.ViewBigbitIntroductionPage _ _ maybePath ->
            maybePath

        Route.ViewBigbitFramePage _ _ frameNumber maybePath ->
            if Util.isNotNothing maybePath then
                maybePath
            else
                Array.get (frameNumber - 1) bigbit.highlightedComments
                    |> Maybe.map .file

        Route.ViewBigbitConclusionPage _ _ maybePath ->
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


{-| Gets the range from the previous frame's selected range if we're on a route
which has a previous frame (Code Frame 2+) and the previous frame has a selected
non-empty range.
-}
previousFrameRange : BigbitCreateData -> Route.Route -> Maybe ( FS.Path, Range.Range )
previousFrameRange createData route =
    case route of
        Route.CreateBigbitCodeFramePage frameNumber _ ->
            Array.get (frameNumber - 2) createData.highlightedComments
                |> Maybe.andThen .fileAndRange
                |> Maybe.andThen
                    (\{ file, range } ->
                        if maybeMapWithDefault Range.isEmptyRange True range then
                            Nothing
                        else
                            Maybe.map ((,) file) range
                    )

        _ ->
            Nothing


{-| Sets one of the highlighted comments at position `index` to it's new value,
if the `index` has no value then the createData is returned unchanged.
-}
updateCreateDataHCAtIndex :
    BigbitCreateData
    -> Int
    -> (BigbitHighlightedCommentForCreate -> BigbitHighlightedCommentForCreate)
    -> BigbitCreateData
updateCreateDataHCAtIndex bigbit index hcUpdater =
    { bigbit
        | highlightedComments =
            ArrayExtra.update index hcUpdater bigbit.highlightedComments
    }


{-| The default create bigbit page data.
-}
defaultBigbitCreateData : BigbitCreateData
defaultBigbitCreateData =
    { name = ""
    , description = ""
    , tags = []
    , tagInput = ""
    , introduction = ""
    , conclusion = ""
    , fs =
        (FS.emptyFS
            { activeFile = Nothing
            , openFS = False
            , actionButtonState = Nothing
            , actionButtonInput = ""
            , actionButtonSubmitConfirmed = False
            }
            { isExpanded = True }
        )
    , highlightedComments =
        Array.fromList
            [ emptyBigbitHighlightCommentForCreate ]
    , previewMarkdown =
        False
    }
