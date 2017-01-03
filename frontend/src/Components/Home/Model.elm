module Components.Home.Model exposing (Model, cacheEncoder, cacheDecoder)

import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.ApiError as ApiError


{-| Home Component Model.
-}
type alias Model =
    { logOutError : Maybe ApiError.ApiError
    }


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "logOutError", Encode.null )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map Model
        (field "logOutError" (Decode.null Nothing))
