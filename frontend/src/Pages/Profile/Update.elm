module Pages.Profile.Update exposing (..)

import Api exposing (api)
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Models.RequestTracker as RT
import Models.User exposing (defaultUserUpdateRecord)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.Profile.Messages exposing (..)
import Pages.Profile.Model exposing (..)


{-| `Profile` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
        OnEditName originalName newName ->
            common.justUpdateModel <| setName originalName newName

        CancelEditedName ->
            if RT.isNotMakingRequest shared.apiRequestTracker RT.UpdateName then
                ( cancelEditingName model
                , { shared
                    | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "profile-account-name"
                  }
                , Cmd.none
                )
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
                        api.post.updateUser
                            { defaultUserUpdateRecord | name = Just validNewName }
                            (common.subMsg << OnSaveEditedNameFailure)
                            (common.subMsg << OnSaveEditedNameSuccess)
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
                ( cancelEditingBio model
                , { shared
                    | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "profile-account-bio"
                  }
                , Cmd.none
                )
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
                        api.post.updateUser
                            { defaultUserUpdateRecord | bio = Just newValidBio }
                            (common.subMsg << OnSaveBioEditedFailure)
                            (common.subMsg << OnSaveEditedBioSuccess)
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
