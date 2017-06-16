module Pages.Profile.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Models.RequestTracker as RT
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
            if RT.isNotMakingRequest shared.apiRequestTracker RT.UpdateName then
                common.justUpdateModel cancelEditingName
            else
                common.doNothing

        SaveEditedName ->
            let
                maybeValidNewName =
                    model.accountName
                        ||> Editable.getBuffer
                        |||> Util.justNonBlankString

                updateNameAction validNewName =
                    common.justProduceCmd <|
                        common.api.post.updateUser
                            { defaultUserUpdateRecord | name = Just validNewName }
                            OnSaveEditedNameFailure
                            OnSaveEditedNameSuccess
            in
                case maybeValidNewName of
                    Nothing ->
                        common.doNothing

                    Just validNewName ->
                        common.makeSingletonRequest RT.UpdateName <| updateNameAction validNewName

        OnSaveEditedNameSuccess updatedUser ->
            ( setAccountNameToNothing model
            , { shared | user = Just updatedUser }
            , Cmd.none
            )
                |> common.andFinishRequest RT.UpdateName

        OnSaveEditedNameFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.UpdateName

        OnEditBio originalBio newBio ->
            common.justUpdateModel <| setBio originalBio newBio

        CancelEditedBio ->
            if RT.isNotMakingRequest shared.apiRequestTracker RT.UpdateBio then
                common.justUpdateModel cancelEditingBio
            else
                common.doNothing

        SaveEditedBio ->
            let
                maybeValidNewBio =
                    model.accountBio
                        ||> Editable.getBuffer
                        |||> Util.justNonBlankString

                updateBioAction newValidBio =
                    common.justProduceCmd <|
                        common.api.post.updateUser
                            { defaultUserUpdateRecord | bio = Just newValidBio }
                            OnSaveBioEditedFailure
                            OnSaveEditedBioSuccess
            in
                case maybeValidNewBio of
                    Nothing ->
                        common.doNothing

                    Just validNewBio ->
                        common.makeSingletonRequest RT.UpdateBio <| updateBioAction validNewBio

        OnSaveEditedBioSuccess updatedUser ->
            ( setAccountBioToNothing model
            , { shared | user = Just updatedUser }
            , Cmd.none
            )
                |> common.andFinishRequest RT.UpdateBio

        OnSaveBioEditedFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.UpdateBio

        LogOut ->
            let
                logoutAction =
                    common.justProduceCmd <| common.api.get.logOut OnLogOutFailure OnLogOutSuccess
            in
                common.makeSingletonRequest RT.Logout logoutAction

        OnLogOutSuccess basicResponse ->
            -- WARNING (unusual behaviour): The base update will check for this message and reset the entire model.
            -- Because of this there is no need to `andFinishRequest` (in fact that will do nothing).
            common.justProduceCmd <| Route.navigateTo Route.RegisterPage

        OnLogOutFailure apiError ->
            common.justSetModel { model | logOutError = Just apiError }
                |> common.andFinishRequest RT.Logout
