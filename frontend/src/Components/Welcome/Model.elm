module Components.Welcome.Model exposing (Model, cacheEncoder, cacheDecoder)

import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.ApiError as ApiError


{-| Welcome Component Model.
-}
type alias Model =
    { email : String
    , password : String
    , confirmPassword : String
    , apiError : Maybe (ApiError.ApiError)
    }


{-| Welcome Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "email", Encode.string model.email )
          -- we don't want to save the password to localStorage
        , ( "password", Encode.string "" )
        , ( "confirmPassword", Encode.string "" )
          -- we don't want errors to persist in localStorage
        , ( "errorCode", Encode.null )
        ]


{-| Welcome Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map4 Model
        (field "email" Decode.string)
        (field "password" Decode.string)
        (field "confirmPassword" Decode.string)
        -- we always save null to localStorage
        (field "errorCode" (Decode.null Nothing))
