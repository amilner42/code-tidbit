module Models.ProfileData exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.ApiError as ApiError


{-| All data related to the profile page.
-}
type alias ProfileData =
    { accountName : Maybe (Editable.Editable String)
    , accountBio : Maybe (Editable.Editable String)
    , logOutError : Maybe ApiError.ApiError
    }


{-| Gets the current account name from the profile data if is not `Nothing`,
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


{-| Gets the current account bio from the profile data if it is not `Nothing`,
otherwise simply returns the backup name.
-}
getBioWithDefault : ProfileData -> String -> String
getBioWithDefault profileData backupBio =
    Util.maybeMapWithDefault Editable.getBuffer backupBio profileData.accountBio


{-| Sets the bio for `accountBio`. This includes initializing if it's `Nothing`
and putting the editable in edit mode.
-}
setBio : String -> String -> ProfileData -> ProfileData
setBio originalBio newBio currentProfileData =
    { currentProfileData
        | accountBio =
            Just <|
                Editable.Editing { originalValue = originalBio, buffer = newBio }
    }


{-| Cancels editing the bio.
-}
cancelEditingBio : ProfileData -> ProfileData
cancelEditingBio profileData =
    { profileData
        | accountBio = Maybe.map (Editable.cancelEditing) profileData.accountBio
    }


{-| Sets the accountBio to `Nothing`
-}
setAccountBioToNothing : ProfileData -> ProfileData
setAccountBioToNothing profileData =
    { profileData
        | accountBio = Nothing
    }


{-| Returns true if the bio is being edited (and has changed).
-}
isEditingBio : ProfileData -> Bool
isEditingBio =
    .accountBio >> Util.maybeMapWithDefault Editable.hasChanged False


{-| The default profile page data.
-}
defaultProfileData : ProfileData
defaultProfileData =
    { accountName = Nothing
    , accountBio = Nothing
    , logOutError = Nothing
    }


{-| ProfileData encoder.
-}
encoder : ProfileData -> Encode.Value
encoder profileData =
    Encode.object
        [ ( "accountName", Util.justValueOrNull (Editable.encoder Encode.string) profileData.accountName )
        , ( "accountBio", Util.justValueOrNull (Editable.encoder Encode.string) profileData.accountBio )
        , ( "logOutError", Encode.null )
        ]


{-| ProfileData decoder.
-}
decoder : Decode.Decoder ProfileData
decoder =
    decode ProfileData
        |> required "accountName" (Decode.maybe <| Editable.decoder Decode.string)
        |> required "accountBio" (Decode.maybe <| Editable.decoder Decode.string)
        |> required "logOutError" (Decode.succeed Nothing)
