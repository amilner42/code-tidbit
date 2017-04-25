module Pages.Profile.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import DefaultServices.Editable as Editable
import Models.Route as Route
import Models.User exposing (defaultUserUpdateRecord)
import Pages.Model exposing (Shared)
import Pages.Profile.Messages exposing (..)
import Pages.Profile.Model exposing (..)


{-| `Profile` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update { doNothing, justSetModel, justUpdateModel, justProduceCmd, api, justSetModalError } msg model shared =
    case msg of
        OnEditName originalName newName ->
            justUpdateModel <| setName originalName newName

        CancelEditedName ->
            justUpdateModel cancelEditingName

        SaveEditedName ->
            case model.accountName of
                Nothing ->
                    doNothing

                Just editableName ->
                    if Editable.bufferIs (not << String.isEmpty) editableName then
                        justProduceCmd <|
                            api.post.updateUser
                                { defaultUserUpdateRecord | name = Just <| Editable.getBuffer editableName }
                                OnSaveEditedNameFailure
                                OnSaveEditedNameSuccess
                    else
                        doNothing

        OnSaveEditedNameSuccess updatedUser ->
            ( setAccountNameToNothing model
            , { shared | user = Just updatedUser }
            , Cmd.none
            )

        OnSaveEditedNameFailure apiError ->
            justSetModalError apiError

        OnEditBio originalBio newBio ->
            justUpdateModel <| setBio originalBio newBio

        CancelEditedBio ->
            justUpdateModel cancelEditingBio

        SaveEditedBio ->
            case model.accountBio of
                Nothing ->
                    doNothing

                Just editableBio ->
                    if Editable.bufferIs (not << String.isEmpty) editableBio then
                        justProduceCmd <|
                            api.post.updateUser
                                { defaultUserUpdateRecord | bio = Just <| Editable.getBuffer editableBio }
                                OnSaveBioEditedFailure
                                OnSaveEditedBioSuccess
                    else
                        doNothing

        OnSaveEditedBioSuccess updatedUser ->
            ( setAccountBioToNothing model
            , { shared | user = Just updatedUser }
            , Cmd.none
            )

        OnSaveBioEditedFailure apiError ->
            justSetModalError apiError

        LogOut ->
            justProduceCmd <| api.get.logOut OnLogOutFailure OnLogOutSuccess

        OnLogOutSuccess basicResponse ->
            -- The base update will check for this message and reset the entire model.
            justProduceCmd <| Route.navigateTo Route.RegisterPage

        OnLogOutFailure apiError ->
            justSetModel <| { model | logOutError = Just apiError }
