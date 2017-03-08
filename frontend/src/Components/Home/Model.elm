module Components.Home.Model exposing (..)

import Array
import DefaultServices.Editable as Editable
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.ApiError as ApiError
import Models.Bigbit as Bigbit
import Models.Snipbit as Snipbit
import Models.HighlightedComment as HC
import Models.ProfileData as ProfileData
import Models.NewStoryData as NewStoryData
import Models.StoryData as StoryData
import Models.ViewStoryData as ViewStoryData


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
    , profileData : ProfileData.ProfileData
    , newStoryData : NewStoryData.NewStoryData
    , storyData : StoryData.StoryData
    , viewStoryData : ViewStoryData.ViewStoryData
    }


{-| The relevant highlighted comments for a selected range as well as the
as a field (`currentHC`) for keeping track of the current HC that the user is
reading.
-}
type alias ViewerRelevantHC hcType =
    { currentHC : Maybe Int
    , relevantHC : Array.Array ( Int, hcType )
    }


{-| Returns true if there are no relevant HC.
-}
viewerRelevantHCIsEmpty : ViewerRelevantHC a -> Bool
viewerRelevantHCIsEmpty =
    .relevantHC >> Array.isEmpty


{-| Returns true if viewing the first frame.
-}
viewerRelevantHCOnFirstFrame : ViewerRelevantHC a -> Bool
viewerRelevantHCOnFirstFrame =
    .currentHC >> ((==) <| Just 0)


{-| Returns true if viewing the last frame.
-}
viewerRelevantHCOnLastFrame : ViewerRelevantHC a -> Bool
viewerRelevantHCOnLastFrame vr =
    vr.currentHC == Just ((Array.length vr.relevantHC) - 1)


{-| Returns the current frame and the total number of frames, 1-based-indexing.
-}
viewerRelevantHCurrentFramePair : ViewerRelevantHC a -> Maybe ( Int, Int )
viewerRelevantHCurrentFramePair vr =
    case vr.currentHC of
        Nothing ->
            Nothing

        Just currentPos ->
            Just ( currentPos + 1, Array.length vr.relevantHC )


{-| Returns true if the user is browsing the relevant HC.
-}
viewerRelevantHCBrowsingFrames : ViewerRelevantHC a -> Bool
viewerRelevantHCBrowsingFrames vr =
    Util.isNotNothing <| viewerRelevantHCurrentFramePair vr


{-| Returns true if the viewer has relevant HC to be browsed but the user is
currently not browsing any.
-}
viewerRelevantHCHasFramesButNotBrowsing : ViewerRelevantHC a -> Bool
viewerRelevantHCHasFramesButNotBrowsing vr =
    Util.isNothing vr.currentHC && (not <| viewerRelevantHCIsEmpty vr)


{-| Goes to the next frame if possible.
-}
viewerRelevantHCGoToNextFrame : ViewerRelevantHC a -> ViewerRelevantHC a
viewerRelevantHCGoToNextFrame vr =
    { vr
        | currentHC =
            if viewerRelevantHCOnLastFrame vr then
                vr.currentHC
            else
                Maybe.map ((+) 1) vr.currentHC
    }


{-| Goes the previous frame if possible.
-}
viewerRelevantHCGoToPreviousFrame : ViewerRelevantHC a -> ViewerRelevantHC a
viewerRelevantHCGoToPreviousFrame vr =
    { vr
        | currentHC =
            if viewerRelevantHCOnFirstFrame vr then
                vr.currentHC
            else
                Maybe.map ((flip (-)) 1) vr.currentHC
    }


{-| ViewerRelevantHC `cacheEncoder`.
-}
viewerRelevantHCCacheEncoder : (hcType -> Encode.Value) -> ViewerRelevantHC hcType -> Encode.Value
viewerRelevantHCCacheEncoder encodeHC viewerRelevantHC =
    Encode.object
        [ ( "currentHC", Util.justValueOrNull Encode.int viewerRelevantHC.currentHC )
        , ( "relevantHC"
          , Encode.array <|
                Array.map
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
            (Decode.array
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
        , ( "viewingSnipbitRelevantHC"
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
        , ( "profileData", ProfileData.encoder model.profileData )
        , ( "newStoryData", NewStoryData.encoder model.newStoryData )
        , ( "storyData", StoryData.encoder model.storyData )
        , ( "viewStoryData", ViewStoryData.encoder model.viewStoryData )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    decode Model
        |> required "logOutError" (Decode.null Nothing)
        |> required "showInfoFor" (Decode.maybe tidbitTypeCacheDecoder)
        |> required "viewingSnipbit" (Decode.maybe Snipbit.snipbitCacheDecoder)
        |> required "viewingSnipbitRelevantHC" (Decode.maybe viewingSnipbitRelevantHCCacheDecoder)
        |> required "viewingBigbit" (Decode.maybe Bigbit.bigbitDecoder)
        |> required "viewingBigbitRelevantHC" (Decode.maybe viewingBigbitRelevantHCCacheDecoder)
        |> required "snipbitCreateData" Snipbit.createDataCacheDecoder
        |> required "bigbitCreateData" Bigbit.bigbitCreateDataCacheDecoder
        |> required "profileData" ProfileData.decoder
        |> required "newStoryData" NewStoryData.decoder
        |> required "storyData" StoryData.decoder
        |> required "viewStoryData" ViewStoryData.decoder


{-| Returns true if the user is browsing the snipbit viewer relevant HC.
-}
isViewSnipbitRHCTabOpen : Model -> Bool
isViewSnipbitRHCTabOpen model =
    maybeMapWithDefault viewerRelevantHCBrowsingFrames False model.viewingSnipbitRelevantHC


{-| Returns true if the user is currently browsing the RHC.
-}
isViewBigbitRHCTabOpen : Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitRHCTabOpen =
    maybeMapWithDefault viewerRelevantHCBrowsingFrames False


{-| Returns true if the user is currently browsing the FS.
-}
isViewBigbitFSTabOpen : Maybe Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitFSTabOpen maybeBigbit maybeRHC =
    (not <| isViewBigbitRHCTabOpen maybeRHC)
        && isViewBigbitFSOpen maybeBigbit


{-| Returns true if the FS is open, this ISNT the same as the FS tab being open,
the FS can be open but have the browsing-rhc over-top it.
-}
isViewBigbitFSOpen : Maybe Bigbit.Bigbit -> Bool
isViewBigbitFSOpen =
    Maybe.map .fs
        >> maybeMapWithDefault Bigbit.isFSOpen False


{-| Returns true if the user is currently browsing the tutorial.
-}
isViewBigbitTutorialTabOpen : Maybe Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitTutorialTabOpen maybeBigbit maybeRHC =
    (not <| isViewBigbitRHCTabOpen maybeRHC)
        && (not <| isViewBigbitFSTabOpen maybeBigbit maybeRHC)
