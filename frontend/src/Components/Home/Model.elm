module Components.Home.Model exposing (Model, cacheEncoder, cacheDecoder)

import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.ApiError as ApiError


{-| Home Component Model. Currently contains no meaningful information, just
random data (strings) to display the cacheing.
-}
type alias Model =
    { dataOne : String
    , dataTwo : String
    , logOutError : Maybe ApiError.ApiError
    }


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "dataOne", Encode.string model.dataOne )
        , ( "dataTwo", Encode.string model.dataTwo )
        , ( "logOutError", Encode.null )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map3 Model
        (field "dataOne" Decode.string)
        (field "dataTwo" Decode.string)
        (field "logOutError" (Decode.null Nothing))
