module Pages.Profile.Update exposing (..)

import Api
import DefaultServices.Editable as Editable
import Models.Route as Route
import Models.User exposing (defaultUserUpdateRecord)
import Pages.DefaultModel exposing (defaultShared)
import Pages.Model exposing (Shared)
import Pages.Profile.Messages exposing (..)
import Pages.Profile.Model exposing (..)


{-| `Profile` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justSetModel newModel =
            ( newModel, shared, Cmd.none )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )
    in
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
                        justProduceCmd <|
                            Api.postUpdateUser
                                { defaultUserUpdateRecord | name = Just <| Editable.getBuffer editableName }
                                OnSaveEditedNameFailure
                                OnSaveEditedNameSuccess

            OnSaveEditedNameSuccess updatedUser ->
                ( setAccountNameToNothing model
                , { shared | user = Just updatedUser }
                , Cmd.none
                )

            OnSaveEditedNameFailure apiError ->
                -- TODO handle failure.
                doNothing

            OnEditBio originalBio newBio ->
                justUpdateModel <| setBio originalBio newBio

            CancelEditedBio ->
                justUpdateModel cancelEditingBio

            SaveEditedBio ->
                case model.accountBio of
                    Nothing ->
                        doNothing

                    Just editableBio ->
                        justProduceCmd <|
                            Api.postUpdateUser
                                { defaultUserUpdateRecord | bio = Just <| Editable.getBuffer editableBio }
                                OnSaveBioEditedFailure
                                OnSaveEditedBioSuccess

            OnSaveEditedBioSuccess updatedUser ->
                ( setAccountBioToNothing model
                , { shared | user = Just updatedUser }
                , Cmd.none
                )

            OnSaveBioEditedFailure apiError ->
                -- TODO handle error.
                doNothing

            LogOut ->
                justProduceCmd <| Api.getLogOut OnLogOutFailure OnLogOutSuccess

            OnLogOutSuccess basicResponse ->
                -- TODO this should send a message up (out-msg pattern) to the base update which will clear all
                -- component data.
                ( model
                , defaultShared
                , Route.navigateTo Route.RegisterPage
                )

            OnLogOutFailure apiError ->
                justSetModel <| { model | logOutError = Just apiError }
