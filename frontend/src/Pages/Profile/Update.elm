module Pages.Profile.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Editable as Editable
import Models.Route as Route
import Models.User exposing (defaultUserUpdateRecord)
import Pages.Model exposing (Shared)
import Pages.Profile.Messages exposing (..)
import Pages.Profile.Model exposing (..)


{-| `Profile` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        OnEditName originalName newName ->
            common.justUpdateModel <| setName originalName newName

        CancelEditedName ->
            common.justUpdateModel cancelEditingName

        SaveEditedName ->
            case model.accountName of
                Nothing ->
                    common.doNothing

                Just editableName ->
                    if Editable.bufferIs (not << String.isEmpty) editableName then
                        common.justProduceCmd <|
                            common.api.post.updateUser
                                { defaultUserUpdateRecord | name = Just <| Editable.getBuffer editableName }
                                OnSaveEditedNameFailure
                                OnSaveEditedNameSuccess
                    else
                        common.doNothing

        OnSaveEditedNameSuccess updatedUser ->
            ( setAccountNameToNothing model
            , { shared | user = Just updatedUser }
            , Cmd.none
            )

        OnSaveEditedNameFailure apiError ->
            common.justSetModalError apiError

        OnEditBio originalBio newBio ->
            common.justUpdateModel <| setBio originalBio newBio

        CancelEditedBio ->
            common.justUpdateModel cancelEditingBio

        SaveEditedBio ->
            case model.accountBio of
                Nothing ->
                    common.doNothing

                Just editableBio ->
                    if Editable.bufferIs (not << String.isEmpty) editableBio then
                        common.justProduceCmd <|
                            common.api.post.updateUser
                                { defaultUserUpdateRecord | bio = Just <| Editable.getBuffer editableBio }
                                OnSaveBioEditedFailure
                                OnSaveEditedBioSuccess
                    else
                        common.doNothing

        OnSaveEditedBioSuccess updatedUser ->
            ( setAccountBioToNothing model
            , { shared | user = Just updatedUser }
            , Cmd.none
            )

        OnSaveBioEditedFailure apiError ->
            common.justSetModalError apiError

        LogOut ->
            common.justProduceCmd <| common.api.get.logOut OnLogOutFailure OnLogOutSuccess

        OnLogOutSuccess basicResponse ->
            -- The base update will check for this message and reset the entire model.
            common.justProduceCmd <| Route.navigateTo Route.RegisterPage

        OnLogOutFailure apiError ->
            common.justSetModel <| { model | logOutError = Just apiError }
