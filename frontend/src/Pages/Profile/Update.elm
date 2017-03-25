module Pages.Profile.Update exposing (..)

import Api
import DefaultServices.Editable as Editable
import DefaultModel exposing (defaultShared)
import Pages.Profile.Model exposing (..)
import Pages.Profile.Messages exposing (..)
import Pages.Model exposing (Shared)
import Models.User exposing (defaultUserUpdateRecord)
import Models.Route as Route


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
            ProfileCancelEditName ->
                justUpdateModel cancelEditingName

            ProfileUpdateName originalName newName ->
                justUpdateModel <| setName originalName newName

            ProfileSaveEditName ->
                case model.accountName of
                    Nothing ->
                        doNothing

                    Just editableName ->
                        justProduceCmd <|
                            Api.postUpdateUser
                                { defaultUserUpdateRecord
                                    | name = Just <| Editable.getBuffer editableName
                                }
                                ProfileSaveNameFailure
                                ProfileSaveNameSuccess

            ProfileSaveNameFailure apiError ->
                -- TODO handle failure.
                doNothing

            ProfileSaveNameSuccess updatedUser ->
                ( setAccountNameToNothing model
                , { shared
                    | user = Just updatedUser
                  }
                , Cmd.none
                )

            ProfileCancelEditBio ->
                justUpdateModel cancelEditingBio

            ProfileUpdateBio originalBio newBio ->
                justUpdateModel <| setBio originalBio newBio

            ProfileSaveEditBio ->
                case model.accountBio of
                    Nothing ->
                        doNothing

                    Just editableBio ->
                        justProduceCmd <|
                            Api.postUpdateUser
                                { defaultUserUpdateRecord
                                    | bio = Just <| Editable.getBuffer editableBio
                                }
                                ProfileSaveBioFailure
                                ProfileSaveBioSuccess

            ProfileSaveBioFailure apiError ->
                -- TODO handle error.
                doNothing

            ProfileSaveBioSuccess updatedUser ->
                ( setAccountBioToNothing model
                , { shared
                    | user = Just updatedUser
                  }
                , Cmd.none
                )

            LogOut ->
                justProduceCmd <| Api.getLogOut OnLogOutFailure OnLogOutSuccess

            OnLogOutFailure apiError ->
                justUpdateModel <|
                    (\currentProfileData ->
                        { currentProfileData
                            | logOutError = Just apiError
                        }
                    )

            OnLogOutSuccess basicResponse ->
                -- TODO this should send a message up (out-msg pattern) to the
                -- base update which will clear all component data.
                ( model
                , defaultShared
                , Route.navigateTo Route.RegisterPage
                )
