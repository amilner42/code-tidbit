module JSON.User exposing (..)

import DefaultServices.Util as Util exposing (justValueOrNull)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.User exposing (..)


{-| `User` safe encoder.
      - Does not encode password.
-}
safeEncoder : User -> Encode.Value
safeEncoder user =
    Encode.object
        [ ( "id", Encode.string user.id )
        , ( "name", Encode.string user.name )
        , ( "email", Encode.string user.email )
        , ( "password", Encode.null )
        , ( "bio", Encode.string user.bio )
        ]


{-| `User` decoder.
-}
decoder : Decode.Decoder User
decoder =
    decode User
        |> required "id" Decode.string
        |> required "name" Decode.string
        |> required "email" Decode.string
        |> optional "password" (Decode.maybe Decode.string) Nothing
        |> required "bio" Decode.string


{-| `UserForRegistration` encoder.
-}
registerEncoder : UserForRegistration -> Encode.Value
registerEncoder registerUser =
    Encode.object
        [ ( "name", Encode.string registerUser.name )
        , ( "email", Encode.string registerUser.email )
        , ( "password", Encode.string registerUser.password )
        ]


{-| `UserForLogin` encoder.
-}
loginEncoder : UserForLogin -> Encode.Value
loginEncoder loginUser =
    Encode.object
        [ ( "email", Encode.string loginUser.email )
        , ( "password", Encode.string loginUser.password )
        ]


{-| `UserUpdateRecord` encoder.
-}
updateRecordEncoder : UserUpdateRecord -> Encode.Value
updateRecordEncoder userUpdateRecord =
    Encode.object
        [ ( "name", justValueOrNull Encode.string userUpdateRecord.name )
        , ( "bio", justValueOrNull Encode.string userUpdateRecord.bio )
        ]
