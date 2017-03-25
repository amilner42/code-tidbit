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
createDataNameFilledIn : Model -> Maybe String
createDataNameFilledIn =
    .name >> Util.justNonEmptyString


{-| Returns the filled-in description or `Nothing`.
-}
createDataDescriptionFilledIn : Model -> Maybe String
createDataDescriptionFilledIn =
    .description >> Util.justNonEmptyString


{-| Returns the filled-in tags or `Nothing`.
-}
createDataTagsFilledIn : Model -> Maybe (List String)
createDataTagsFilledIn =
    .tags >> Util.justNonEmptyList


{-| Returns the filled-in code or `Nothing`.
-}
createDataCodeFilledIn : Model -> Maybe String
createDataCodeFilledIn =
    .code >> Util.justNonEmptyString


{-| Returns the filled-in introduction or `Nothing`.
-}
createDataIntroductionFilledIn : Model -> Maybe String
createDataIntroductionFilledIn =
    .introduction >> Util.justNonEmptyString


{-| Returns the filled-in conclusion or `Nothing`.
-}
createDataConclusionFilledIn : Model -> Maybe String
createDataConclusionFilledIn =
    .conclusion >> Util.justNonEmptyString


{-| Returns the filled in highlighted comments or `Nothing`.
-}
createDataHighlightedCommentsFilledIn : Model -> Maybe (Array.Array HighlightedComment)
createDataHighlightedCommentsFilledIn =
    .highlightedComments
        >> (Array.foldr
                (\maybeHC previousHC ->
                    case ( maybeHC.range, maybeHC.comment ) of
                        ( Just aRange, Just aComment ) ->
                            if
                                (String.length aComment > 0)
                                    && (not <| Range.isEmptyRange aRange)
                            then
                                Maybe.map
                                    ((::)
                                        { range = aRange
                                        , comment = aComment
                                        }
                                    )
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
createDataCodeTabFilledIn : Model -> Bool
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


{-| Given the createData, returns the publication data if everything is filled
out, otherwise returns `Nothing`.
-}
createDataToPublicationData : Model -> Maybe SnipbitForPublication
createDataToPublicationData createData =
    case
        ( createDataNameFilledIn createData
        , createDataDescriptionFilledIn createData
        , createData.language
        , createDataTagsFilledIn createData
        , createDataCodeFilledIn createData
        , createDataIntroductionFilledIn createData
        , createDataConclusionFilledIn createData
        , createDataHighlightedCommentsFilledIn createData
        )
    of
        ( Just name, Just description, Just language, Just tags, Just code, Just introduction, Just conclusion, Just highlightedComments ) ->
            Just <|
                SnipbitForPublication
                    language
                    name
                    description
                    tags
                    code
                    introduction
                    conclusion
                    highlightedComments

        _ ->
            Nothing


{-| Gets the range from the previous frame's selected range if we're on a route
which has a previous frame (Code Frame 2+) and the previous frame has a selected
non-empty range.
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
                (containsQuery <| Tuple.second langPair)
                    || (containsQuery <| toString <| Tuple.first langPair)
            )
