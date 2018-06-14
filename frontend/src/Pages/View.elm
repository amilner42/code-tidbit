module Pages.View exposing (view)

import DefaultServices.Util as Util
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, classList, src)
import Html.Events exposing (onClick)
import Models.ApiError as ApiError
import Models.Bigbit as Bigbit
import Models.Route as Route
import Pages.Browse.Model as BrowseModel
import Pages.Browse.View as BrowseView
import Pages.Create.Model as CreateModel
import Pages.Create.View as CreateView
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateBigbit.View as CreateBigbitView
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import Pages.CreateSnipbit.View as CreateSnipbitView
import Pages.DevelopStory.Model as DevelopStoryModel
import Pages.DevelopStory.View as DevelopStoryView
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model, Shared)
import Pages.NewStory.Model as NewStoryModel
import Pages.NewStory.View as NewStoryView
import Pages.Notifications.Model as NotificationsModel
import Pages.Notifications.View as NotificationsView
import Pages.Profile.Model as ProfileModel
import Pages.Profile.View as ProfileView
import Pages.ViewBigbit.Model as ViewBigbitModel
import Pages.ViewBigbit.View as ViewBigbitView
import Pages.ViewSnipbit.Model as ViewSnipbitModel
import Pages.ViewSnipbit.View as ViewSnipbitView
import Pages.ViewStory.Model as ViewStoryModel
import Pages.ViewStory.View as ViewStoryView
import Pages.Welcome.Model as WelcomeModel
import Pages.Welcome.View as WelcomeView


{-| `Base` view.

NOTE: This is the Html entry point to the entire application.

-}
view : Model -> Html.Html Msg
view model =
    div
        [ class "base-page-wrapper" ]
        [ div
            [ class "base-page" ]
            [ navbarIfOnRoute model
            , viewForRoute model
            ]

        -- The modal for displaying errors.
        , Util.maybeMapWithDefault errorModal Util.hiddenDiv model.shared.apiModalError

        -- The modal for telling the user they need to sign up (likely because they clicked something requiring auth).
        , Util.maybeMapWithDefault (signUpModal model.shared.route) Util.hiddenDiv model.shared.userNeedsAuthModal

        -- Used for smooth scrolling to the bottom.
        , div [ class "invisible-bottom" ] []
        ]


{-| A basic modal for displaying the message in human readable format.
-}
errorModal : ApiError.ApiError -> Html Msg
errorModal apiError =
    div
        []
        [ -- The modal background.
          div
            [ class "modal-bg"
            , onClick CloseErrorModal
            ]
            []

        -- The actual modal box.
        , div
            [ class "modal-box" ]
            [ div
                [ class "modal-title" ]
                [ text "An Error Occured" ]
            , div
                [ class "modal-message" ]
                [ text <| ApiError.humanReadable apiError ]
            ]
        ]


{-| A basic modal for telling the user that they need to log in or sign up.
-}
signUpModal : Route.Route -> String -> Html Msg
signUpModal currentRoute modalMessage =
    div
        [ class "sign-up-modal" ]
        [ -- The modal background.
          div
            [ class "modal-bg"
            , onClick CloseSignUpModal
            ]
            []

        -- The actual modal.
        , div
            [ class "modal-box" ]
            [ div
                [ class "modal-title" ]
                [ text "Join the Community" ]
            , div
                [ class "modal-message" ]
                [ text modalMessage ]
            , div
                [ class "centered-buttons" ]
                [ div
                    [ class "login"
                    , onClick <| GoTo { wipeModalError = False } <| Route.LoginPage (Just <| Route.toHashUrl currentRoute)
                    ]
                    [ text "LOGIN" ]
                , div
                    [ class "sign-up"
                    , onClick <| GoTo { wipeModalError = False } <| Route.RegisterPage (Just <| Route.toHashUrl currentRoute)
                    ]
                    [ text "SIGN UP" ]
                ]
            ]
        ]


{-| Loads the correct view depending on the route we are on.

NOTE: The way we structure the routing we don't need to do ANY checking here to see if the route being loaded is correct
(eg. maybe their loading a route that needs auth but they're not logged in) because that logic is already handled
in `handleLocationChange`. At the point this function is called, the user has already changed their route, we've
already approved that the route change is good and updated the model, and now we just need to render it.

-}
viewForRoute : Model -> Html.Html Msg
viewForRoute model =
    let
        welcomePage =
            welcomeView model.welcomePage model.shared

        viewSnipbitPage =
            viewSnipbitView model.viewSnipbitPage model.shared

        viewBigbitPage =
            viewBigbitView model.viewBigbitPage model.shared

        viewStoryPage =
            viewStoryView model.viewStoryPage model.shared

        profilePage =
            profileView model.profilePage model.shared

        newStoryPage =
            newStoryView model.newStoryPage model.shared

        createPage =
            createView model.createPage model.shared

        developStoryPage =
            developStoryView model.developStoryPage model.shared

        createSnipbitPage =
            createSnipbitView model.createSnipbitPage model.shared

        createBigbitPage =
            createBigbitView model.createBigbitPage model.shared

        browsePage =
            browseView model.browsePage model.shared

        notificationsPage =
            notificationsView model.notificationsPage model.shared
    in
    case model.shared.route of
        Route.RegisterPage _ ->
            welcomePage

        Route.LoginPage _ ->
            welcomePage

        Route.BrowsePage ->
            browsePage

        Route.ViewSnipbitFramePage _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitQuestionsPage _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitQuestionPage _ _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitAnswersPage _ _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitAnswerPage _ _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitQuestionCommentsPage _ _ _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitAnswerCommentsPage _ _ _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitAskQuestion _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitAnswerQuestion _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitEditQuestion _ _ _ ->
            viewSnipbitPage

        Route.ViewSnipbitEditAnswer _ _ _ ->
            viewSnipbitPage

        Route.ViewBigbitFramePage _ _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitQuestionsPage _ _ ->
            viewBigbitPage

        Route.ViewBigbitQuestionPage _ _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitAnswersPage _ _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitAnswerPage _ _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitQuestionCommentsPage _ _ _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitAnswerCommentsPage _ _ _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitAskQuestion _ _ ->
            viewBigbitPage

        Route.ViewBigbitEditQuestion _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitAnswerQuestion _ _ _ ->
            viewBigbitPage

        Route.ViewBigbitEditAnswer _ _ _ ->
            viewBigbitPage

        Route.ViewStoryPage _ ->
            viewStoryPage

        Route.CreatePage ->
            createPage

        Route.CreateSnipbitInfoPage ->
            createSnipbitPage

        Route.CreateSnipbitCodeFramePage _ ->
            createSnipbitPage

        Route.CreateBigbitNamePage ->
            createBigbitPage

        Route.CreateBigbitDescriptionPage ->
            createBigbitPage

        Route.CreateBigbitTagsPage ->
            createBigbitPage

        Route.CreateBigbitCodeFramePage _ _ ->
            createBigbitPage

        Route.CreateStoryNamePage _ ->
            newStoryPage

        Route.CreateStoryDescriptionPage _ ->
            newStoryPage

        Route.CreateStoryTagsPage _ ->
            newStoryPage

        Route.DevelopStoryPage _ ->
            developStoryPage

        Route.ProfilePage ->
            profilePage

        Route.NotificationsPage ->
            notificationsPage


{-| `Welcome` view.
-}
welcomeView : WelcomeModel.Model -> Shared -> Html.Html Msg
welcomeView welcomeModel shared =
    WelcomeView.view WelcomeMessage welcomeModel shared


{-| `ViewSnipbit` view.
-}
viewSnipbitView : ViewSnipbitModel.Model -> Shared -> Html.Html Msg
viewSnipbitView viewSnipbitModel shared =
    ViewSnipbitView.view ViewSnipbitMessage viewSnipbitModel shared


{-| `ViewBigbit` view.
-}
viewBigbitView : ViewBigbitModel.Model -> Shared -> Html.Html Msg
viewBigbitView viewBigbitModel shared =
    ViewBigbitView.view ViewBigbitMessage viewBigbitModel shared


{-| `ViewStory` view.
-}
viewStoryView : ViewStoryModel.Model -> Shared -> Html.Html Msg
viewStoryView viewStoryModel shared =
    ViewStoryView.view ViewStoryMessage viewStoryModel shared


{-| `Profile` view.
-}
profileView : ProfileModel.Model -> Shared -> Html.Html Msg
profileView profileModel shared =
    ProfileView.view ProfileMessage profileModel shared


{-| `NewStory` view.
-}
newStoryView : NewStoryModel.Model -> Shared -> Html.Html Msg
newStoryView newStoryModel shared =
    NewStoryView.view NewStoryMessage newStoryModel shared


{-| `Create` view.
-}
createView : CreateModel.Model -> Shared -> Html.Html Msg
createView createModel shared =
    CreateView.view CreateMessage createModel shared


{-| `DevelopStory` view.
-}
developStoryView : DevelopStoryModel.Model -> Shared -> Html.Html Msg
developStoryView developStoryModel shared =
    DevelopStoryView.view DevelopStoryMessage developStoryModel shared


{-| `CreateSnipbit` view.
-}
createSnipbitView : CreateSnipbitModel.Model -> Shared -> Html.Html Msg
createSnipbitView createSnipbitModel shared =
    CreateSnipbitView.view CreateSnipbitMessage createSnipbitModel shared


{-| `CreateBigbit` view.
-}
createBigbitView : CreateBigbitModel.Model -> Shared -> Html.Html Msg
createBigbitView createBigbitModel shared =
    Html.map CreateBigbitMessage (CreateBigbitView.view createBigbitModel shared)


{-| `Browse` view.
-}
browseView : BrowseModel.Model -> Shared -> Html.Html Msg
browseView browseModel shared =
    BrowseView.view BrowseMessage browseModel shared


{-| `Notifications` view.
-}
notificationsView : NotificationsModel.Model -> Shared -> Html.Html Msg
notificationsView notificationsModel shared =
    NotificationsView.view NotificationsMessage notificationsModel shared


{-| Displays the navbar if the route is not on the welcome page.
-}
navbarIfOnRoute : Model -> Html Msg
navbarIfOnRoute model =
    case model.shared.route of
        Route.LoginPage _ ->
            Util.hiddenDiv

        Route.RegisterPage _ ->
            Util.hiddenDiv

        _ ->
            navbar model


{-| Horizontal navbar to go above the views.
-}
navbar : Model -> Html Msg
navbar model =
    let
        shared =
            model.shared

        browseViewSelected =
            case shared.route of
                Route.BrowsePage ->
                    True

                Route.ViewSnipbitFramePage _ _ _ ->
                    True

                Route.ViewSnipbitQuestionsPage _ _ ->
                    True

                Route.ViewSnipbitQuestionPage _ _ _ _ ->
                    True

                Route.ViewSnipbitAnswersPage _ _ _ _ ->
                    True

                Route.ViewSnipbitAnswerPage _ _ _ _ ->
                    True

                Route.ViewSnipbitQuestionCommentsPage _ _ _ _ _ ->
                    True

                Route.ViewSnipbitAnswerCommentsPage _ _ _ _ _ ->
                    True

                Route.ViewSnipbitAskQuestion _ _ ->
                    True

                Route.ViewSnipbitAnswerQuestion _ _ _ ->
                    True

                Route.ViewSnipbitEditQuestion _ _ _ ->
                    True

                Route.ViewSnipbitEditAnswer _ _ _ ->
                    True

                Route.ViewBigbitFramePage _ _ _ _ ->
                    True

                Route.ViewBigbitQuestionsPage _ _ ->
                    True

                Route.ViewBigbitQuestionPage _ _ _ _ ->
                    True

                Route.ViewBigbitAnswersPage _ _ _ _ ->
                    True

                Route.ViewBigbitAnswerPage _ _ _ _ ->
                    True

                Route.ViewBigbitQuestionCommentsPage _ _ _ _ _ ->
                    True

                Route.ViewBigbitAnswerCommentsPage _ _ _ _ _ ->
                    True

                Route.ViewBigbitAskQuestion _ _ ->
                    True

                Route.ViewBigbitEditQuestion _ _ _ ->
                    True

                Route.ViewBigbitAnswerQuestion _ _ _ ->
                    True

                Route.ViewBigbitEditAnswer _ _ _ ->
                    True

                Route.ViewStoryPage _ ->
                    True

                _ ->
                    False

        profileViewSelected =
            shared.route == Route.ProfilePage

        createViewSelected =
            case shared.route of
                Route.CreateSnipbitCodeFramePage _ ->
                    True

                Route.CreateBigbitCodeFramePage _ _ ->
                    True

                Route.DevelopStoryPage _ ->
                    True

                Route.CreateStoryNamePage _ ->
                    True

                Route.CreateStoryDescriptionPage _ ->
                    True

                Route.CreateStoryTagsPage _ ->
                    True

                _ ->
                    List.member
                        shared.route
                        [ Route.CreatePage
                        , Route.CreateSnipbitInfoPage
                        , Route.CreateBigbitNamePage
                        , Route.CreateBigbitDescriptionPage
                        , Route.CreateBigbitTagsPage
                        ]

        notificationsViewSelected =
            Route.NotificationsPage == shared.route

        currentURLHash =
            Route.toHashUrl shared.route

        registerRouteWithRedirectQP =
            Route.RegisterPage <| Just currentURLHash

        loginRouteWithRedirectQP =
            Route.LoginPage <| Just currentURLHash
    in
    div
        [ classList
            [ ( "nav", True )
            , ( "nav-wide-2", isWideNav2 model )
            , ( "nav-wide-3", isWideNav3 model )
            ]
        ]
        [ img
            [ class "logo"
            , src "assets/ct-logo-small.png"
            ]
            []
        , Route.navigationNode
            (Just ( Route.Route Route.BrowsePage, GoTo { wipeModalError = False } Route.BrowsePage ))
            [ classList [ ( "hidden", Util.isNotNothing shared.user ) ] ]
            [ div
                [ class "nav-btn left code-tidbit" ]
                [ text "Code Tidbit" ]
            ]
        , Route.navigationNode
            (Just ( Route.Route Route.BrowsePage, GoTo { wipeModalError = False } Route.BrowsePage ))
            [ classList [ ( "hidden", Util.isNothing shared.user ) ] ]
            [ div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", browseViewSelected )
                    ]
                ]
                [ text "Browse" ]
            ]
        , Route.navigationNode
            (Just ( Route.Route Route.CreatePage, GoTo { wipeModalError = False } Route.CreatePage ))
            [ classList [ ( "hidden", Util.isNothing shared.user ) ] ]
            [ div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", createViewSelected )
                    ]
                ]
                [ text "Create" ]
            ]
        , Route.navigationNode
            (Just ( Route.Route Route.NotificationsPage, GoTo { wipeModalError = False } Route.NotificationsPage ))
            [ classList [ ( "hidden", Util.isNothing shared.user ) ] ]
            [ div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", notificationsViewSelected )
                    ]
                ]
                [ text "Notifications" ]
            ]
        , Route.navigationNode
            (Just ( Route.Route Route.ProfilePage, GoTo { wipeModalError = False } Route.ProfilePage ))
            [ classList [ ( "hidden", Util.isNothing shared.user ) ] ]
            [ div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "selected", profileViewSelected )
                    ]
                ]
                [ text "Profile" ]
            ]
        , Route.navigationNode
            (Just ( Route.Route registerRouteWithRedirectQP, GoTo { wipeModalError = False } registerRouteWithRedirectQP ))
            [ classList [ ( "hidden", Util.isNotNothing shared.user ) ] ]
            [ div
                [ class "nav-btn sign-up right" ]
                [ text "Sign Up" ]
            ]
        , Route.navigationNode
            (Just ( Route.Route loginRouteWithRedirectQP, GoTo { wipeModalError = False } loginRouteWithRedirectQP ))
            [ classList [ ( "hidden", Util.isNotNothing shared.user ) ] ]
            [ div
                [ class "nav-btn login right" ]
                [ text "Login" ]
            ]
        ]


{-| Returns true if the nav needs to be `$min-width-supported-2` wide.

Currently wide-mode-2 is required for viewing bigbits when the FS is expanded.

-}
isWideNav2 : Model -> Bool
isWideNav2 model =
    let
        viewBigbitFSOpen =
            ViewBigbitModel.isBigbitFSOpen model.viewBigbitPage.bigbit
    in
    case model.shared.route of
        Route.ViewBigbitFramePage _ _ _ _ ->
            viewBigbitFSOpen

        _ ->
            False


{-| Returns true if the nav needs to be `$min-width-supported-3` wide.

Currently wide-mode-3 is required for creating bigbits when the fs is expanded.

-}
isWideNav3 : Model -> Bool
isWideNav3 model =
    case model.shared.route of
        Route.CreateBigbitCodeFramePage _ _ ->
            Bigbit.isFSOpen model.createBigbitPage.fs

        _ ->
            False
