module Pages.CreateBigbit.Model exposing (..)

import Array
import Char
import DefaultServices.ArrayExtra as ArrayExtra
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Models.Bigbit exposing (FileMetadata, FolderMetadata, HighlightedComment)
import Models.Range as Range
import Models.Route as Route


{-| `CreateBigbit` model.
-}
type alias Model =
    { name : String
    , description : String
    , tags : List String
    , tagInput : String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure FSMetadata FolderMetadata FileMetadata
    , highlightedComments : Array.Array HighlightedCommentForCreate
    , previewMarkdown : Bool
    , confirmedRemoveFrame : Bool
    }


{-| The metadata connected to the FS.
-}
type alias FSMetadata =
    { activeFile : Maybe FS.Path
    , openFS : Bool
    , actionButtonState : Maybe FSActionButtonState
    , actionButtonInput : String
    , actionButtonSubmitConfirmed : Bool
    }


{-| The highlighted comments used during bigbit creation.
-}
type alias HighlightedCommentForCreate =
    { comment : String
    , fileAndRange : Maybe FileAndRange
    }


{-| A file and a range, used in bigbit highlighted comments.
-}
type alias FileAndRange =
    { range : Maybe Range.Range
    , file : FS.Path
    }


{-| A full bigbit ready for publication.
-}
type alias BigbitForPublication =
    { name : String
    , description : String
    , tags : List String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure () () { language : Editor.Language }
    , highlightedComments : List HighlightedComment
    }


{-| Basic union to keep track of the current state of the action buttons in the file structure.
-}
type FSActionButtonState
    = AddingFolder
    | AddingFile
    | RemovingFolder
    | RemovingFile


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
                    || List.member char [ '_', '-', '.', '/' ]
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
nameFilledIn : Model -> Maybe String
nameFilledIn =
    .name >> Util.justStringInRange 1 50


{-| Returns the filled-in description or `Nothing`.
-}
descriptionFilledIn : Model -> Maybe String
descriptionFilledIn =
    .description >> Util.justStringInRange 1 300


{-| Returns the filled-in tags or `Nothing`.
-}
tagsFilledIn : Model -> Maybe (List String)
tagsFilledIn =
    .tags >> Util.justNonEmptyList


{-| Returns the filled-in introduction or `Nothing`.
-}
introductionFilledIn : Model -> Maybe String
introductionFilledIn =
    .introduction >> Util.justNonEmptyString


{-| Returns the filled-in conclusion or `Nothing`.
-}
conclusionFilledIn : Model -> Maybe String
conclusionFilledIn =
    .conclusion >> Util.justNonEmptyString


{-| Returns the filled-in highlighted comments [in publication form] or `Nothing`.
-}
highlightedCommentsFilledIn : Model -> Maybe (List HighlightedComment)
highlightedCommentsFilledIn =
    .highlightedComments
        >> Array.foldr
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


{-| Returns true if all data in the code tab is filled-in.
-}
codeTabFilledIn : Model -> Bool
codeTabFilledIn model =
    case ( introductionFilledIn model, conclusionFilledIn model, highlightedCommentsFilledIn model ) of
        ( Just _, Just _, Just _ ) ->
            True

        _ ->
            False


{-| Given the model, returns BigbitForPublication if the data is completely filled out, otherwise returns `Nothing`.
-}
toPublicationData : Model -> Maybe BigbitForPublication
toPublicationData model =
    case
        ( nameFilledIn model
        , descriptionFilledIn model
        , tagsFilledIn model
        , introductionFilledIn model
        , conclusionFilledIn model
        , highlightedCommentsFilledIn model
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
                    (model.fs |> FS.metaMap (always ()) (always ()) identity)
                    hc

        _ ->
            Nothing


{-| Gets the active file (on create page) for a specific frame.
-}
getActiveFileForFrame : Int -> Model -> Maybe FS.Path
getActiveFileForFrame frameNumber bigbit =
    Array.get (frameNumber - 1) bigbit.highlightedComments
        |> Maybe.andThen .fileAndRange
        |> Maybe.map .file


{-| Sets one of the highlighted comments at position `index` to it's new value, if the `index` has no value then the
createData is returned unchanged.
-}
updateHCAtIndex : Model -> Int -> (HighlightedCommentForCreate -> HighlightedCommentForCreate) -> Model
updateHCAtIndex bigbit index hcUpdater =
    { bigbit | highlightedComments = ArrayExtra.update index hcUpdater bigbit.highlightedComments }


{-| Checks equality against the current state of `actionButtonState`.
-}
fsActionStateEquals :
    Maybe FSActionButtonState
    -> FS.FileStructure { a | actionButtonState : Maybe FSActionButtonState } b c
    -> Bool
fsActionStateEquals maybeActionState =
    FS.getFSMetadata >> .actionButtonState >> (==) maybeActionState


{-| Creates an empty folder.
-}
defaultEmptyFolder : FS.Folder FolderMetadata FileMetadata
defaultEmptyFolder =
    FS.emptyFolder { isExpanded = True }


{-| Clears the action button input.
-}
clearActionButtonInput : FS.FileStructure FSMetadata b c -> FS.FileStructure FSMetadata b c
clearActionButtonInput =
    FS.updateFSMetadata (\fsMetadata -> { fsMetadata | actionButtonInput = "" })


{-| Gets the range from the previous frame's selected range if we're on a route which has a previous frame
(Code Frame 2+) and the previous frame has a selected non-empty range.
-}
previousFrameRange : Model -> Route.Route -> Maybe ( FS.Path, Range.Range )
previousFrameRange model route =
    case route of
        Route.CreateBigbitCodeFramePage frameNumber _ ->
            Array.get (frameNumber - 2) model.highlightedComments
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


{-| Helper for setting the actionButtonSubmitConfirmed.
-}
setActionButtonSubmitConfirmed :
    Bool
    -> FS.FileStructure { a | actionButtonSubmitConfirmed : Bool } b c
    -> FS.FileStructure { a | actionButtonSubmitConfirmed : Bool } b c
setActionButtonSubmitConfirmed newConfirmValue fs =
    fs |> FS.updateFSMetadata (\fsMetadata -> { fsMetadata | actionButtonSubmitConfirmed = newConfirmValue })
