module Models.Snipbit exposing (..)

import Array
import Autocomplete as AC
import Date
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.Editor as Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)
import Models.HighlightedComment exposing (MaybeHighlightedComment, HighlightedComment, maybeHighlightedCommentCacheEncoder, maybeHighlightedCommentCacheDecoder, highlightedCommentEncoder, highlightedCommentDecoder)
import Models.Range as Range
import Models.Route as Route


{-| A snipbit as seen in the db.
-}
type alias Snipbit =
    { id : String
    , language : Language
    , name : String
    , description : String
    , tags : List String
    , code : String
    , introduction : String
    , conclusion : String
    , highlightedComments : Array.Array HighlightedComment
    , author : String
    , createdAt : Date.Date
    , lastModified : Date.Date
    }


{-| A full SnipbitForPublication ready for publication.
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


{-| The data for a snipbit being created.
-}
type alias SnipbitCreateData =
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


{-| For DRY code to create encoders for `Snipbit` and `SnipbitForPublication`.
-}
createSnipbitEncoder model extraFields =
    Encode.object <|
        List.concat
            [ [ ( "language", languageCacheEncoder model.language )
              , ( "name", Encode.string model.name )
              , ( "description", Encode.string model.description )
              , ( "tags", Encode.list <| List.map Encode.string model.tags )
              , ( "code", Encode.string model.code )
              , ( "introduction", Encode.string model.introduction )
              , ( "conclusion", Encode.string model.conclusion )
              , ( "highlightedComments"
                , Encode.array <|
                    Array.map
                        highlightedCommentEncoder
                        model.highlightedComments
                )
              ]
            , extraFields
            ]


{-| Snipbit `cacheDecoder`.
-}
snipbitCacheDecoder : Decode.Decoder Snipbit
snipbitCacheDecoder =
    snipbitDecoder


{-| Snipbit `cacheEncoder`.
-}
snipbitCacheEncoder : Snipbit -> Encode.Value
snipbitCacheEncoder =
    snipbitEncoder


{-| Snipbit `encoder`.
-}
snipbitEncoder : Snipbit -> Encode.Value
snipbitEncoder snipbit =
    createSnipbitEncoder
        snipbit
        [ ( "id", Encode.string snipbit.id )
        , ( "author", Encode.string snipbit.author )
        , ( "createdAt", Util.dateEncoder snipbit.createdAt )
        , ( "lastModified", Util.dateEncoder snipbit.lastModified )
        ]


{-| Snipbit `decoder`.
-}
snipbitDecoder : Decode.Decoder Snipbit
snipbitDecoder =
    decode Snipbit
        |> required "id" Decode.string
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array highlightedCommentDecoder)
        |> required "author" Decode.string
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder


{-| Identical to the encoder, but used to follow naming conventions.
-}
snipbitForPublicationCacheEncoder =
    snipbitForPublicationEncoder


{-| Identical to the decoder, but used to follow naming conventions.
-}
snipbitForPublicationCacheDecoder =
    snipbitForSymbolDecoder


{-| SnipbitForPublication `encoder`.
-}
snipbitForPublicationEncoder : SnipbitForPublication -> Encode.Value
snipbitForPublicationEncoder snipbitForPublication =
    createSnipbitEncoder snipbitForPublication []


{-| SnipbitForPublication `decoder`.
-}
snipbitForSymbolDecoder : Decode.Decoder SnipbitForPublication
snipbitForSymbolDecoder =
    decode SnipbitForPublication
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array highlightedCommentDecoder)


{-| SnipbitCreateData `cacheEncoder`.
-}
createDataCacheEncoder : SnipbitCreateData -> Encode.Value
createDataCacheEncoder snipbitCreateData =
    Encode.object
        [ ( "language"
          , Util.justValueOrNull
                languageCacheEncoder
                snipbitCreateData.language
          )
        , ( "languageQueryACState", Encode.null )
        , ( "languageListHowManyToShow", Encode.int snipbitCreateData.languageListHowManyToShow )
        , ( "languageQuery", Encode.string snipbitCreateData.languageQuery )
        , ( "name", Encode.string snipbitCreateData.name )
        , ( "description", Encode.string snipbitCreateData.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string snipbitCreateData.tags
          )
        , ( "tagInput", Encode.string snipbitCreateData.tagInput )
        , ( "code", Encode.string snipbitCreateData.code )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    maybeHighlightedCommentCacheEncoder
                    snipbitCreateData.highlightedComments
          )
        , ( "introduction", Encode.string snipbitCreateData.introduction )
        , ( "conclusion", Encode.string snipbitCreateData.conclusion )
        , ( "previewMarkdown", Encode.bool snipbitCreateData.previewMarkdown )
        ]


{-| SnipbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder SnipbitCreateData
createDataCacheDecoder =
    decode SnipbitCreateData
        |> required "language" (Decode.maybe languageCacheDecoder)
        |> required "languageQueryACState" (Decode.succeed AC.empty)
        |> required "languageListHowManyToShow" (Decode.int)
        |> required "languageQuery" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
        |> required "code" Decode.string
        |> required
            "highlightedComments"
            (Decode.array maybeHighlightedCommentCacheDecoder)
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "previewMarkdown" Decode.bool


{-| Returns the filled-in name or `Nothing`.
-}
createDataNameFilledIn : SnipbitCreateData -> Maybe String
createDataNameFilledIn =
    .name >> Util.justNonEmptyString


{-| Returns the filled-in description or `Nothing`.
-}
createDataDescriptionFilledIn : SnipbitCreateData -> Maybe String
createDataDescriptionFilledIn =
    .description >> Util.justNonEmptyString


{-| Returns the filled-in tags or `Nothing`.
-}
createDataTagsFilledIn : SnipbitCreateData -> Maybe (List String)
createDataTagsFilledIn =
    .tags >> Util.justNonEmptyList


{-| Returns the filled-in code or `Nothing`.
-}
createDataCodeFilledIn : SnipbitCreateData -> Maybe String
createDataCodeFilledIn =
    .code >> Util.justNonEmptyString


{-| Returns the filled-in introduction or `Nothing`.
-}
createDataIntroductionFilledIn : SnipbitCreateData -> Maybe String
createDataIntroductionFilledIn =
    .introduction >> Util.justNonEmptyString


{-| Returns the filled-in conclusion or `Nothing`.
-}
createDataConclusionFilledIn : SnipbitCreateData -> Maybe String
createDataConclusionFilledIn =
    .conclusion >> Util.justNonEmptyString


{-| Returns the filled in highlighted comments or `Nothing`.
-}
createDataHighlightedCommentsFilledIn : SnipbitCreateData -> Maybe (Array.Array HighlightedComment)
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
createDataCodeTabFilledIn : SnipbitCreateData -> Bool
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
createDataToPublicationData : SnipbitCreateData -> Maybe SnipbitForPublication
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
previousFrameRange : SnipbitCreateData -> Route.Route -> Maybe Range.Range
previousFrameRange createData route =
    case route of
        Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
            Array.get (frameNumber - 2) createData.highlightedComments
                |> Maybe.andThen .range
                |> Maybe.andThen Range.nonEmptyRangeOrNothing

        _ ->
            Nothing


{-| The default create snipbit page data.
-}
defaultSnipbitCreateData : SnipbitCreateData
defaultSnipbitCreateData =
    { language = Nothing
    , languageQueryACState = AC.empty
    , languageListHowManyToShow = (List.length Editor.humanReadableListOfLanguages)
    , languageQuery = ""
    , name = ""
    , description = ""
    , tags = []
    , tagInput = ""
    , code = ""
    , highlightedComments =
        Array.fromList
            [ { comment = Nothing, range = Nothing }
            ]
    , introduction = ""
    , conclusion = ""
    , previewMarkdown = False
    }
