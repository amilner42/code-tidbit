module Models.ProfileData exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


{-| All data related to the profile page.
-}
type alias ProfileData =
    { accountName : Maybe (Editable.Editable String)
    }


{-| ProfileData encoder.
-}
encoder : ProfileData -> Encode.Value
encoder profileData =
    Encode.object
        [ ( "accountName", Util.justValueOrNull (Editable.encoder Encode.string) profileData.accountName ) ]


{-| ProfileData decoder.
-}
decoder : Decode.Decoder ProfileData
decoder =
    decode ProfileData
        |> required "accountName" (Decode.maybe <| Editable.decoder Decode.string)


{-| Gets the current account name from the profile data if is not nothing,
otherwise simply returns the backup name.
-}
getNameWithDefault : ProfileData -> String -> String
getNameWithDefault profileData backupName =
    Util.maybeMapWithDefault Editable.getBuffer backupName profileData.accountName


{-| Sets the name for `accountName`. This include initializing if it's `Nothing`
and putting the editable in edit mode.
-}
setName : String -> String -> ProfileData -> ProfileData
setName originalName newName currentProfileData =
    { currentProfileData
        | accountName =
            Just <|
                Editable.Editing { originalValue = originalName, buffer = newName }
    }


{-| Returns true if the name is currently being edited and has a new value
compared to the original.
-}
isEditingName : ProfileData -> Bool
isEditingName =
    .accountName >> Util.maybeMapWithDefault Editable.hasChanged False


{-| Cancels editing the name.
-}
cancelEditingName : ProfileData -> ProfileData
cancelEditingName profileData =
    { profileData
        | accountName = Maybe.map (Editable.cancelEditing) profileData.accountName
    }


{-| Sets the accountName to `Nothing`.
-}
setAccountNameToNothing : ProfileData -> ProfileData
setAccountNameToNothing profileData =
    { profileData
        | accountName = Nothing
    }
