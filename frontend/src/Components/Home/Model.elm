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
import Models.Completed as Completed
import Models.ViewSnipbitData as ViewSnipbitData
import Models.ViewBigbitData as ViewBigbitData
import Models.CreateData as CreateData


{-| Home Component Model.
-}
type alias Model =
    { createData : CreateData.CreateData
    , viewSnipbitData : ViewSnipbitData.ViewSnipbitData
    , viewBigbitData : ViewBigbitData.ViewBigbitData
    , snipbitCreateData : Snipbit.SnipbitCreateData
    , bigbitCreateData : Bigbit.BigbitCreateData
    , profileData : ProfileData.ProfileData
    , newStoryData : NewStoryData.NewStoryData
    , storyData : StoryData.StoryData
    }


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "createData", CreateData.encoder model.createData )
        , ( "viewSnipbitData", ViewSnipbitData.encoder model.viewSnipbitData )
        , ( "viewBigbitData", ViewBigbitData.encoder model.viewBigbitData )
        , ( "snipbitCreateData", Snipbit.createDataCacheEncoder model.snipbitCreateData )
        , ( "bigbitCreateData", Bigbit.bigbitCreateDataCacheEncoder model.bigbitCreateData )
        , ( "profileData", ProfileData.encoder model.profileData )
        , ( "newStoryData", NewStoryData.encoder model.newStoryData )
        , ( "storyData", StoryData.encoder model.storyData )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    decode Model
        |> required "createData" CreateData.decoder
        |> required "viewSnipbitData" ViewSnipbitData.decoder
        |> required "viewBigbitData" ViewBigbitData.decoder
        |> required "snipbitCreateData" Snipbit.createDataCacheDecoder
        |> required "bigbitCreateData" Bigbit.bigbitCreateDataCacheDecoder
        |> required "profileData" ProfileData.decoder
        |> required "newStoryData" NewStoryData.decoder
        |> required "storyData" StoryData.decoder
