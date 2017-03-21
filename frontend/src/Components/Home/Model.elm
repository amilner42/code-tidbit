module Components.Home.Model exposing (..)

import Array
import DefaultServices.Editable as Editable
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Bigbit as JSONBigbit
import JSON.CreateData as JSONCreateData
import JSON.NewStoryData as JSONNewStoryData
import JSON.ProfileData as JSONProfileData
import JSON.StoryData as JSONStoryData
import JSON.Snipbit as JSONSnipbit
import JSON.ViewBigbitData as JSONViewBigbitData
import JSON.ViewSnipbitData as JSONViewSnipbitData
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
        [ ( "createData", JSONCreateData.encoder model.createData )
        , ( "viewSnipbitData", JSONViewSnipbitData.encoder model.viewSnipbitData )
        , ( "viewBigbitData", JSONViewBigbitData.encoder model.viewBigbitData )
        , ( "snipbitCreateData", JSONSnipbit.createDataEncoder model.snipbitCreateData )
        , ( "bigbitCreateData", JSONBigbit.createDataEncoder model.bigbitCreateData )
        , ( "profileData", JSONProfileData.encoder model.profileData )
        , ( "newStoryData", JSONNewStoryData.encoder model.newStoryData )
        , ( "storyData", JSONStoryData.encoder model.storyData )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    decode Model
        |> required "createData" JSONCreateData.decoder
        |> required "viewSnipbitData" JSONViewSnipbitData.decoder
        |> required "viewBigbitData" JSONViewBigbitData.decoder
        |> required "snipbitCreateData" JSONSnipbit.createDataDecoder
        |> required "bigbitCreateData" JSONBigbit.createDataDecoder
        |> required "profileData" JSONProfileData.decoder
        |> required "newStoryData" JSONNewStoryData.decoder
        |> required "storyData" JSONStoryData.decoder
