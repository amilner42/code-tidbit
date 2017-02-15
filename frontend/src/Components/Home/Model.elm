module Components.Home.Model exposing (..)

import DefaultServices.Util as Util
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.ApiError as ApiError
import Models.Bigbit as Bigbit
import Models.Snipbit as Snipbit
import Models.HighlightedComment as HC


{-| Home Component Model.
-}
type alias Model =
    { logOutError : Maybe ApiError.ApiError
    , showInfoFor : Maybe TidbitType
    , viewingSnipbit : Maybe Snipbit.Snipbit
    , viewingSnipbitRelevantHC : Maybe ViewingSnipbitRelevantHC
    , viewingBigbit : Maybe Bigbit.Bigbit
    , viewingBigbitRelevantHC : Maybe ViewingBigbitRelevantHC
    , snipbitCreateData : Snipbit.SnipbitCreateData
    , bigbitCreateData : Bigbit.BigbitCreateData
    }


{-| The relevant highlighted comments for a selected range as well as the
as a field (`currentHC`) for keeping track of the current HC that the user is
reading.
-}
type alias ViewerRelevantHC hcType =
    { currentHC : Maybe Int
    , relevantHC : List ( Int, hcType )
    }


{-| ViewerRelevantHC `cacheEncoder`.
-}
viewerRelevantHCCacheEncoder : (hcType -> Encode.Value) -> ViewerRelevantHC hcType -> Encode.Value
viewerRelevantHCCacheEncoder encodeHC viewerRelevantHC =
    Encode.object
        [ ( "currentHC", Util.justValueOrNull Encode.int viewerRelevantHC.currentHC )
        , ( "relevantHC"
          , Encode.list <|
                List.map
                    (\hc ->
                        Encode.object
                            [ ( "frameIndex", Encode.int <| Tuple.first hc )
                            , ( "hc", encodeHC <| Tuple.second hc )
                            ]
                    )
                    viewerRelevantHC.relevantHC
          )
        ]


{-| ViewerRelevantHC `cacheDecoder`.
-}
viewerRelevantHCCacheDecoder : Decode.Decoder hcType -> Decode.Decoder (ViewerRelevantHC hcType)
viewerRelevantHCCacheDecoder decodeHC =
    decode ViewerRelevantHC
        |> required "currentHC" (Decode.maybe Decode.int)
        |> required "relevantHC"
            (Decode.list
                (decode (,)
                    |> required "frameIndex" Decode.int
                    |> required "hc" decodeHC
                )
            )


{-| Used when viewing a snipbit and the user highlights part of the code.
-}
type alias ViewingSnipbitRelevantHC =
    ViewerRelevantHC HC.HighlightedComment


{-| ViewingSnipbitRelevantHC `cacheEncoder`.
-}
viewingSnipbitRelevantHCCacheEncoder : ViewingSnipbitRelevantHC -> Encode.Value
viewingSnipbitRelevantHCCacheEncoder =
    viewerRelevantHCCacheEncoder HC.highlightedCommentEncoder


{-| ViewingSnipbitRelevantHC `cacheDecoder`.
-}
viewingSnipbitRelevantHCCacheDecoder : Decode.Decoder ViewingSnipbitRelevantHC
viewingSnipbitRelevantHCCacheDecoder =
    viewerRelevantHCCacheDecoder HC.highlightedCommentDecoder


{-| Used when viewing a bigbit and the user highlights part of the code.
-}
type alias ViewingBigbitRelevantHC =
    ViewerRelevantHC Bigbit.BigbitHighlightedCommentForPublication


{-| ViewingBigbitRelevantHC `cacheEncoder`.
-}
viewingBigbitRelevantHCCacheEncoder : ViewingBigbitRelevantHC -> Encode.Value
viewingBigbitRelevantHCCacheEncoder =
    viewerRelevantHCCacheEncoder Bigbit.bigbitHighlightedCommentForPublicationCacheEncoder


{-| ViewingBigbitRelevantHC `cacheDecoder`.
-}
viewingBigbitRelevantHCCacheDecoder : Decode.Decoder ViewingBigbitRelevantHC
viewingBigbitRelevantHCCacheDecoder =
    viewerRelevantHCCacheDecoder Bigbit.bigbitHighlightedCommentForPublicationCacheDecoder


{-| Basic union to keep track of tidbit types.
-}
type TidbitType
    = SnipBit
    | BigBit


{-| TidbitType `cacheEncoder`.
-}
tidbitTypeCacheEncoder : TidbitType -> Encode.Value
tidbitTypeCacheEncoder =
    toString >> Encode.string


{-| TidbitType `cacheDecoder`.
-}
tidbitTypeCacheDecoder : Decode.Decoder TidbitType
tidbitTypeCacheDecoder =
    let
        fromStringDecoder encodedTidbitType =
            case encodedTidbitType of
                "SnipBit" ->
                    Decode.succeed SnipBit

                "BigBit" ->
                    Decode.succeed BigBit

                _ ->
                    Decode.fail <| encodedTidbitType ++ " is not a valid encoded tidbit type."
    in
        Decode.andThen fromStringDecoder Decode.string


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "logOutError", Encode.null )
        , ( "showInfoFor", Util.justValueOrNull tidbitTypeCacheEncoder model.showInfoFor )
        , ( "viewingSnipbit", Util.justValueOrNull Snipbit.snipbitCacheEncoder model.viewingSnipbit )
        , ( "viewingSnipbitRelevantRanges"
          , Util.justValueOrNull viewingSnipbitRelevantHCCacheEncoder model.viewingSnipbitRelevantHC
          )
        , ( "viewingBigbit", Util.justValueOrNull Bigbit.bigbitEncoder model.viewingBigbit )
        , ( "viewingBigbitRelevantHC"
          , Util.justValueOrNull viewingBigbitRelevantHCCacheEncoder model.viewingBigbitRelevantHC
          )
        , ( "snipbitCreateData"
          , Snipbit.createDataCacheEncoder model.snipbitCreateData
          )
        , ( "bigbitCreateData", Bigbit.bigbitCreateDataCacheEncoder model.bigbitCreateData )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map8 Model
        (field "logOutError" (Decode.null Nothing))
        (field "showInfoFor" (Decode.maybe tidbitTypeCacheDecoder))
        (field "viewingSnipbit" (Decode.maybe Snipbit.snipbitCacheDecoder))
        (field "viewingSnipbitRelevantHC" (Decode.maybe viewingSnipbitRelevantHCCacheDecoder))
        (field "viewingBigbit" (Decode.maybe Bigbit.bigbitDecoder))
        (field "viewingBigbitRelevantHC" (Decode.maybe viewingBigbitRelevantHCCacheDecoder))
        (field "snipbitCreateData" Snipbit.createDataCacheDecoder)
        (field "bigbitCreateData" Bigbit.bigbitCreateDataCacheDecoder)
