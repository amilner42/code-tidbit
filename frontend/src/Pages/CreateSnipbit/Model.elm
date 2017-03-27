module Pages.CreateSnipbit.Model exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import Elements.Editor as Editor exposing (Language)
import Models.HighlightedComment exposing (MaybeHighlightedComment, HighlightedComment)
import Models.Range as Range
import Models.Route as Route


{-| `CreateSnipbit` model.
-}
type alias Model =
    { language : Maybe Language
    , languageQueryACState : AC.State
    , languageListHowManyToShow : Int
    , languageQuery : String
    , name : String
    , description : String
    , tags : List String
    , tagInput : String
    , code : String
    , highlightedComments : Array.Array MaybeHighlightedComment
    , introduction : String
    , conclusion : String
    , previewMarkdown : Bool
    }


{-| A full Snipbit ready for publication.
-}
type alias SnipbitForPublication =
    { language : Language
    , name : String
    , description : String
    , tags : List String
    , code : String
    , introduction : String
    , conclusion : String
    , highlightedComments : Array.Array HighlightedComment
    }


{-| Returns the filled-in name or `Nothing`.
-}
nameFilledIn : Model -> Maybe String
nameFilledIn =
    .name >> Util.justNonEmptyString


{-| Returns the filled-in description or `Nothing`.
-}
descriptionFilledIn : Model -> Maybe String
descriptionFilledIn =
    .description >> Util.justNonEmptyString


{-| Returns the filled-in tags or `Nothing`.
-}
tagsFilledIn : Model -> Maybe (List String)
tagsFilledIn =
    .tags >> Util.justNonEmptyList


{-| Returns the filled-in code or `Nothing`.
-}
codeFilledIn : Model -> Maybe String
codeFilledIn =
    .code >> Util.justNonEmptyString


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


{-| Returns the filled in highlighted comments or `Nothing`.
-}
highlightedCommentsFilledIn : Model -> Maybe (Array.Array HighlightedComment)
highlightedCommentsFilledIn =
    .highlightedComments
        >> (Array.foldr
                (\maybeHC previousHC ->
                    case ( maybeHC.range, maybeHC.comment ) of
                        ( Just aRange, Just aComment ) ->
                            if (String.length aComment > 0) && (not <| Range.isEmptyRange aRange) then
                                Maybe.map
                                    ((::) { range = aRange, comment = aComment })
                                    previousHC
                            else
                                Nothing

                        _ ->
                            Nothing
                )
                (Just [])
           )
        >> Maybe.map Array.fromList


{-| Checks if all the data in the code tab is filled in.
-}
codeTabFilledIn : Model -> Bool
codeTabFilledIn model =
    case ( introductionFilledIn model, conclusionFilledIn model, highlightedCommentsFilledIn model ) of
        ( Just _, Just _, Just _ ) ->
            True

        _ ->
            False


{-| Given the model, returns the publication data if everything is filled out, otherwise returns `Nothing`.
-}
toPublicationData : Model -> Maybe SnipbitForPublication
toPublicationData model =
    case
        ( nameFilledIn model
        , descriptionFilledIn model
        , model.language
        , tagsFilledIn model
        , codeFilledIn model
        , introductionFilledIn model
        , conclusionFilledIn model
        , highlightedCommentsFilledIn model
        )
    of
        ( Just name, Just description, Just language, Just tags, Just code, Just introduction, Just conclusion, Just highlightedComments ) ->
            Just <|
                SnipbitForPublication language name description tags code introduction conclusion highlightedComments

        _ ->
            Nothing


{-| Gets the range from the previous frame's selected range if we're on a route which has a previous frame
(Code Frame 2+) and the previous frame has a selected non-empty range.
-}
previousFrameRange : Model -> Route.Route -> Maybe Range.Range
previousFrameRange model route =
    case route of
        Route.CreateSnipbitCodeFramePage frameNumber ->
            Array.get (frameNumber - 2) model.highlightedComments
                |> Maybe.andThen .range
                |> Maybe.andThen Range.nonEmptyRangeOrNothing

        _ ->
            Nothing


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Language, String ) -> List ( Language, String )
filterLanguagesByQuery query =
    let
        -- Ignores case.
        containsQuery =
            String.toLower >> String.contains (String.toLower query)
    in
        List.filter
            (\langPair ->
                (containsQuery <| Tuple.second langPair) || (containsQuery <| toString <| Tuple.first langPair)
            )
