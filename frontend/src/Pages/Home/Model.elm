module Pages.Home.Model exposing (..)

import Array
import DefaultServices.Editable as Editable
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Bigbit
import JSON.CreateData
import JSON.NewStoryData
import JSON.ProfileData
import JSON.StoryData
import JSON.Snipbit
import JSON.ViewBigbitData
import JSON.ViewSnipbitData
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
        [ ( "createData", JSON.CreateData.encoder model.createData )
        , ( "viewSnipbitData", JSON.ViewSnipbitData.encoder model.viewSnipbitData )
        , ( "viewBigbitData", JSON.ViewBigbitData.encoder model.viewBigbitData )
        , ( "snipbitCreateData", JSON.Snipbit.createDataEncoder model.snipbitCreateData )
        , ( "bigbitCreateData", JSON.Bigbit.createDataEncoder model.bigbitCreateData )
        , ( "profileData", JSON.ProfileData.encoder model.profileData )
        , ( "newStoryData", JSON.NewStoryData.encoder model.newStoryData )
        , ( "storyData", JSON.StoryData.encoder model.storyData )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    decode Model
        |> required "createData" JSON.CreateData.decoder
        |> required "viewSnipbitData" JSON.ViewSnipbitData.decoder
        |> required "viewBigbitData" JSON.ViewBigbitData.decoder
        |> required "snipbitCreateData" JSON.Snipbit.createDataDecoder
        |> required "bigbitCreateData" JSON.Bigbit.createDataDecoder
        |> required "profileData" JSON.ProfileData.decoder
        |> required "newStoryData" JSON.NewStoryData.decoder
        |> required "storyData" JSON.StoryData.decoder
