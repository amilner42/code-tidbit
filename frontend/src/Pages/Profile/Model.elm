module Pages.Profile.Model exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util


{-| `Profile` model.
-}
type alias Model =
    { accountName : Maybe (Editable.Editable String)
    , accountBio : Maybe (Editable.Editable String)
    }


{-| Gets the current account name from the profile data if is not `Nothing`, otherwise simply returns the backup name.
-}
getNameWithDefault : Model -> String -> String
getNameWithDefault model backupName =
    Util.maybeMapWithDefault Editable.getBuffer backupName model.accountName


{-| Sets the name for `accountName`. This include initializing if it's `Nothing` and putting the editable in edit mode.
-}
setName : String -> String -> Model -> Model
setName originalName newName model =
    { model | accountName = Just <| Editable.Editing { originalValue = originalName, buffer = newName } }


{-| Returns true if the name is currently being edited and has a new value compared to the original.
-}
isEditingName : Model -> Bool
isEditingName =
    .accountName >> Util.maybeMapWithDefault Editable.hasChanged False


{-| Cancels editing the name.
-}
cancelEditingName : Model -> Model
cancelEditingName model =
    { model | accountName = Maybe.map Editable.cancelEditing model.accountName }


{-| Sets the accountName to `Nothing`.
-}
setAccountNameToNothing : Model -> Model
setAccountNameToNothing model =
    { model | accountName = Nothing }


{-| Gets the current account bio from the profile data if it is not `Nothing`, otherwise simply returns the backup name.
-}
getBioWithDefault : Model -> String -> String
getBioWithDefault model backupBio =
    Util.maybeMapWithDefault Editable.getBuffer backupBio model.accountBio


{-| Sets the bio for `accountBio`. This includes initializing if it's `Nothing` and putting the editable in edit mode.
-}
setBio : String -> String -> Model -> Model
setBio originalBio newBio model =
    { model | accountBio = Just <| Editable.Editing { originalValue = originalBio, buffer = newBio } }


{-| Cancels editing the bio.
-}
cancelEditingBio : Model -> Model
cancelEditingBio model =
    { model | accountBio = Maybe.map Editable.cancelEditing model.accountBio }


{-| Sets the accountBio to `Nothing`
-}
setAccountBioToNothing : Model -> Model
setAccountBioToNothing model =
    { model | accountBio = Nothing }


{-| Returns true if the bio is being edited (and has changed).
-}
isEditingBio : Model -> Bool
isEditingBio =
    .accountBio >> Util.maybeMapWithDefault Editable.hasChanged False
