module Api exposing (API, api)

import Date
import DefaultServices.Http as HttpService
import DefaultServices.Util as Util
import JSON.BasicResponse
import JSON.Bigbit
import JSON.Completed
import JSON.Content
import JSON.ContentPointer
import JSON.IDResponse
import JSON.Opinion
import JSON.QA
import JSON.Range
import JSON.Rating
import JSON.Snipbit
import JSON.Story
import JSON.Tidbit
import JSON.TidbitPointer
import JSON.User
import JSON.Vote
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Content as Content
import Models.ContentPointer as ContentPointer
import Models.IDResponse as IDResponse
import Models.Opinion as Opinion
import Models.QA as QA
import Models.Range as Range
import Models.Rating as Rating
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.Vote as Vote
import Pages.CreateBigbit.JSON as CreateBigbitJSON
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateSnipbit.JSON as CreateSnipbitJSON
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import ProjectTypeAliases exposing (..)


{-| The API to access the backend.
-}
type alias API b =
    { get :
        { -- Gets the ID of the user that exists with that email (if one exists, otherwise returns `Nothing`).
          userExists : Email -> (ApiError.ApiError -> b) -> (Maybe UserID -> b) -> Cmd b

        -- Gets the users account, or an error if unauthenticated.
        , account : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b

        -- Gets stories, you can use query params to customize the search. Refer to the backend to see the options.
        , stories : QueryParams -> (ApiError.ApiError -> b) -> (List Story.Story -> b) -> Cmd b

        -- Gets a single story.
        , story : StoryID -> (ApiError.ApiError -> b) -> (Story.Story -> b) -> Cmd b

        -- Gets a single expanded story.
        , expandedStory : StoryID -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b

        -- Gets a single expanded story with the completed list attached.
        , expandedStoryWithCompleted : StoryID -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b

        -- Queries the API to log the user out, which should send a response to delete the cookies.
        , logOut : (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b

        -- Get's a snipbit.
        , snipbit : SnipbitID -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b

        -- Get's a bigbit.
        , bigbit : BigbitID -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b

        -- Gets tidbits, you can use query params to customize the search. Refer to the backend to see the options.
        , tidbits : QueryParams -> (ApiError.ApiError -> b) -> (List Tidbit.Tidbit -> b) -> Cmd b

        -- Get's content, you can use query params to customize the search. Refer to the backend to see the options.
        , content : QueryParams -> (ApiError.ApiError -> b) -> (List Content.Content -> b) -> Cmd b

        -- Get's a user's opinion.
        , opinion : ContentPointer.ContentPointer -> (ApiError.ApiError -> b) -> (Maybe Rating.Rating -> b) -> Cmd b

        -- Get's the QA object for a specific snipbit.
        , snipbitQA : SnipbitID -> (ApiError.ApiError -> b) -> (QA.SnipbitQA -> b) -> Cmd b

        -- Get's the QA object for a specific bigbit.
        , bigbitQA : BigbitID -> (ApiError.ApiError -> b) -> (QA.BigbitQA -> b) -> Cmd b
        }
    , post :
        { -- Logs user in and returns the user, unless invalid credentials.
          login : User.UserForLogin -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b

        -- Registers the user and returns the user, unless invalid new credentials.
        , register : User.UserForRegistration -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b

        -- Creates a new snipbit.
        , createSnipbit : CreateSnipbitModel.SnipbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b

        -- Creates a new bigbit.
        , createBigbit : CreateBigbitModel.BigbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b

        -- Updates a user.
        , updateUser : User.UserUpdateRecord -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b

        -- Creates a new story.
        , createNewStory : Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b

        -- Updates the information for a story.
        , updateStoryInformation : StoryID -> Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b

        -- Updates a story with new tidbits.
        , addTidbitsToStory : StoryID -> List TidbitPointer.TidbitPointer -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b

        -- Adds a new `Completed` to the list of things the user has completed.
        , addCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b

        -- Removes a `Completed` from the users list of completed tidbits.
        , removeCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b

        -- Checks if something is completed, does not modify the db.
        , checkCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b

        -- Adds an opinion for a logged-in user.
        , addOpinion : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b

        -- Removes an opinion for a logged-in user.
        , removeOpinion : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b

        -- Ask a question on a snipbit.
        , askQuestionOnSnipbit : SnipbitID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (QA.Question Range.Range -> b) -> Cmd b

        -- Ask a question on a bigbit.
        , askQuestionOnBigbit : BigbitID -> QuestionText -> QA.BigbitCodePointer -> (ApiError.ApiError -> b) -> (QA.Question QA.BigbitCodePointer -> b) -> Cmd b

        -- Edit a question on a snipbit.
        , editQuestionOnSnipbit : SnipbitID -> QuestionID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b

        -- Edit a question on a bigbit.
        , editQuestionOnBigbit : BigbitID -> QuestionID -> QuestionText -> QA.BigbitCodePointer -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b

        -- Deletes a question.
        , deleteQuestion : TidbitPointer.TidbitPointer -> QuestionID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Place your vote (`Vote`) on a question.
        , rateQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Vote.Vote -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Remove a rating from a question.
        , removeQuestionRating : TidbitPointer.TidbitPointer -> QuestionID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Sets the pin-state of a question.
        , pinQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Bool -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Answer a question.
        , answerQuestion : TidbitPointer.TidbitPointer -> QuestionID -> AnswerText -> (ApiError.ApiError -> b) -> (QA.Answer -> b) -> Cmd b

        -- Edit an answer.
        , editAnswer : TidbitPointer.TidbitPointer -> AnswerID -> AnswerText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b

        -- Deletes an answer.
        , deleteAnswer : TidbitPointer.TidbitPointer -> AnswerID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Rates an answer.
        , rateAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Vote.Vote -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Removes a rating from an answer.
        , removeAnswerRating : TidbitPointer.TidbitPointer -> AnswerID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Sets the pin-state of an answer.
        , pinAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Bool -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Comment on a question (adds to the existing comment thread).
        , commentOnQuestion : TidbitPointer.TidbitPointer -> QuestionID -> CommentText -> (ApiError.ApiError -> b) -> (QA.QuestionComment -> b) -> Cmd b

        -- Edit a comment on a question.
        , editQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b

        -- Delete a comment on a question.
        , deleteQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b

        -- Comment on an answer.
        , commentOnAnswer : TidbitPointer.TidbitPointer -> QuestionID -> AnswerID -> CommentText -> (ApiError.ApiError -> b) -> (QA.AnswerComment -> b) -> Cmd b

        -- Edit a comment on an answer.
        , editAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b

        -- Delete a comment on an answer.
        , deleteAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        }
    }


{-| The access point to the API.

Currently takes the API base url as configuration (different in prod and dev).
-}
api : String -> API b
api apiBaseUrl =
    let
        {- Helper for querying the API (GET), automatically adds the apiBaseUrl prefix. -}
        apiGet : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
        apiGet url =
            HttpService.get (apiBaseUrl ++ url)

        {- Helper for qeurying the API (POST), automatically adds the apiBaseUrl prefix. -}
        apiPost : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
        apiPost url =
            HttpService.post (apiBaseUrl ++ url)
    in
        { get =
            { userExists =
                (\email -> apiGet ("userID" :/: email) (Decode.maybe Decode.string))
            , account =
                apiGet "account" JSON.User.decoder
            , stories =
                (\queryParams ->
                    apiGet ("stories" ++ Util.queryParamsToString queryParams) (Decode.list <| JSON.Story.decoder)
                )
            , story =
                (\storyID -> apiGet ("stories" :/: storyID) JSON.Story.decoder)
            , expandedStory =
                (\storyID ->
                    apiGet
                        ("stories" :/: storyID ++ Util.queryParamsToString [ ( "expandStory", Just "true" ) ])
                        JSON.Story.expandedStoryDecoder
                )
            , expandedStoryWithCompleted =
                (\storyID ->
                    apiGet
                        ("stories"
                            :/: storyID
                            ++ Util.queryParamsToString
                                [ ( "expandStory", Just "true" )
                                , ( "withCompleted", Just "true" )
                                ]
                        )
                        JSON.Story.expandedStoryDecoder
                )
            , logOut =
                apiGet "logOut" JSON.BasicResponse.decoder
            , snipbit =
                (\snipbitID -> apiGet ("snipbits" :/: snipbitID) JSON.Snipbit.decoder)
            , bigbit =
                (\bigbitID -> apiGet ("bigbits" :/: bigbitID) JSON.Bigbit.decoder)
            , tidbits =
                (\queryParams ->
                    apiGet
                        ("tidbits" ++ (Util.queryParamsToString queryParams))
                        (Decode.list JSON.Tidbit.decoder)
                )
            , content =
                (\queryParams ->
                    apiGet
                        ("content" ++ (Util.queryParamsToString queryParams))
                        (Decode.list JSON.Content.decoder)
                )
            , opinion =
                (\contentPointer ->
                    apiGet
                        ("account/getOpinion"
                            :/: (toString <| JSON.ContentPointer.contentTypeToInt contentPointer.contentType)
                            :/: (contentPointer.contentID)
                        )
                        (Decode.maybe JSON.Rating.decoder)
                )
            , snipbitQA =
                (\snipbitID -> apiGet ("qa/1" :/: snipbitID) JSON.QA.snipbitQADecoder)
            , bigbitQA =
                (\bigbitID -> apiGet ("qa/2" :/: bigbitID) JSON.QA.bigbitQADecoder)
            }
        , post =
            { login =
                (\user -> apiPost "login" JSON.User.decoder (JSON.User.loginEncoder user))
            , register =
                (\user -> apiPost "register" JSON.User.decoder (JSON.User.registerEncoder user))
            , createSnipbit =
                (\snipbit ->
                    apiPost
                        "snipbits"
                        JSON.IDResponse.decoder
                        (CreateSnipbitJSON.publicationEncoder snipbit)
                )
            , createBigbit =
                (\bigbit ->
                    apiPost
                        "bigbits"
                        JSON.IDResponse.decoder
                        (CreateBigbitJSON.publicationEncoder bigbit)
                )
            , updateUser =
                (\updateRecord ->
                    apiPost
                        "account"
                        JSON.User.decoder
                        (JSON.User.updateRecordEncoder updateRecord)
                )
            , createNewStory =
                (\newStory ->
                    apiPost
                        "stories"
                        JSON.IDResponse.decoder
                        (JSON.Story.newStoryEncoder newStory)
                )
            , updateStoryInformation =
                (\storyID newStoryInformation ->
                    apiPost
                        ("stories" :/: storyID :/: "information")
                        JSON.IDResponse.decoder
                        (JSON.Story.newStoryEncoder newStoryInformation)
                )
            , addTidbitsToStory =
                (\storyID newTidbitPointers ->
                    apiPost
                        ("stories" :/: storyID :/: "addTidbits")
                        JSON.Story.expandedStoryDecoder
                        (Encode.list <| List.map JSON.TidbitPointer.encoder newTidbitPointers)
                )
            , addCompleted =
                (\completed ->
                    apiPost
                        "account/addCompleted"
                        JSON.IDResponse.decoder
                        (JSON.Completed.encoder completed)
                )
            , removeCompleted =
                (\completed ->
                    apiPost
                        "account/removeCompleted"
                        Decode.bool
                        (JSON.Completed.encoder completed)
                )
            , checkCompleted =
                (\completed ->
                    apiPost
                        "account/checkCompleted"
                        Decode.bool
                        (JSON.Completed.encoder completed)
                )
            , addOpinion =
                (\opinion ->
                    apiPost
                        "account/addOpinion"
                        Decode.bool
                        (JSON.Opinion.encoder opinion)
                )
            , removeOpinion =
                (\opinion ->
                    apiPost
                        "account/removeOpinion"
                        Decode.bool
                        (JSON.Opinion.encoder opinion)
                )
            , askQuestionOnSnipbit =
                (\snipbitID questionText codePointer ->
                    apiPost
                        ("qa/1" :/: snipbitID :/: "askQuestion")
                        (JSON.QA.questionDecoder JSON.Range.decoder)
                        (Encode.object
                            [ ( "questionText", Encode.string questionText )
                            , ( "codePointer", JSON.Range.encoder codePointer )
                            ]
                        )
                )
            , askQuestionOnBigbit =
                (\bigbitID questionText codePointer ->
                    apiPost
                        ("qa/2" :/: bigbitID :/: "askQuestion")
                        (JSON.QA.questionDecoder JSON.QA.bigbitCodePointerDecoder)
                        (Encode.object
                            [ ( "questionText", Encode.string questionText )
                            , ( "codePointer", JSON.QA.bigbitCodePointerEncoder codePointer )
                            ]
                        )
                )
            , editQuestionOnSnipbit =
                (\snipbitID questionID questionText codePointer ->
                    apiPost
                        ("qa/1" :/: snipbitID :/: "editQuestion")
                        Util.dateDecoder
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "questionText", Encode.string questionText )
                            , ( "codePointer", JSON.Range.encoder codePointer )
                            ]
                        )
                )
            , editQuestionOnBigbit =
                (\bigbitID questionID questionText codePointer ->
                    apiPost
                        ("qa/2" :/: bigbitID :/: "editQuestion")
                        Util.dateDecoder
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "questionText", Encode.string questionText )
                            , ( "codePointer", JSON.QA.bigbitCodePointerEncoder codePointer )
                            ]
                        )
                )
            , deleteQuestion =
                (\tidbitPointer questionID ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteQuestion")
                        (decode ())
                        (Encode.object [ ( "questionID", Encode.string questionID ) ])
                )
            , rateQuestion =
                (\tidbitPointer questionID vote ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "rateQuestion")
                        (decode ())
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "vote", JSON.Vote.encoder vote )
                            ]
                        )
                )
            , removeQuestionRating =
                (\tidbitPointer questionID ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "removeQuestionRating")
                        (decode ())
                        (Encode.object [ ( "questionID", Encode.string questionID ) ])
                )
            , pinQuestion =
                (\tidbitPointer questionID pin ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "pinQuestion")
                        (decode ())
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "pin", Encode.bool pin )
                            ]
                        )
                )
            , answerQuestion =
                (\tidbitPointer questionID answerText ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "answerQuestion")
                        JSON.QA.answerDecoder
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "answerText", Encode.string answerText )
                            ]
                        )
                )
            , editAnswer =
                (\tidbitPointer answerID answerText ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "editAnswer")
                        Util.dateDecoder
                        (Encode.object
                            [ ( "answerID", Encode.string answerID )
                            , ( "answerText", Encode.string answerText )
                            ]
                        )
                )
            , deleteAnswer =
                (\tidbitPointer answerID ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteAnswer")
                        (decode ())
                        (Encode.object [ ( "answerID", Encode.string answerID ) ])
                )
            , rateAnswer =
                (\tidbitPointer answerID vote ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "rateAnswer")
                        (decode ())
                        (Encode.object
                            [ ( "answerID", Encode.string answerID )
                            , ( "vote", JSON.Vote.encoder vote )
                            ]
                        )
                )
            , removeAnswerRating =
                (\tidbitPointer answerID ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "removeAnswerRating")
                        (decode ())
                        (Encode.object [ ( "answerID", Encode.string answerID ) ])
                )
            , pinAnswer =
                (\tidbitPointer answerID pin ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "pinAnswer")
                        (decode ())
                        (Encode.object
                            [ ( "answerID", Encode.string answerID )
                            , ( "pin", Encode.bool pin )
                            ]
                        )
                )
            , commentOnQuestion =
                (\tidbitPointer questionID commentText ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "comment/question")
                        (JSON.QA.questionCommentDecoder)
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "commentText", Encode.string commentText )
                            ]
                        )
                )
            , editQuestionComment =
                (\tidbitPointer commentID commentText ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "editComment/question")
                        Util.dateDecoder
                        (Encode.object
                            [ ( "commentText", Encode.string commentText )
                            , ( "commentID", Encode.string commentID )
                            ]
                        )
                )
            , deleteQuestionComment =
                (\tidbitPointer commentID ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteComment/question")
                        (decode ())
                        (Encode.object [ ( "commentID", Encode.string commentID ) ])
                )
            , commentOnAnswer =
                (\tidbitPointer questionID answerID commentText ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "comment/answer")
                        JSON.QA.answerCommentDecoder
                        (Encode.object
                            [ ( "questionID", Encode.string questionID )
                            , ( "answerID", Encode.string answerID )
                            , ( "commentText", Encode.string commentText )
                            ]
                        )
                )
            , editAnswerComment =
                (\tidbitPointer commentID commentText ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "editComment/answer")
                        Util.dateDecoder
                        (Encode.object
                            [ ( "commentID", Encode.string commentID )
                            , ( "commentText", Encode.string commentText )
                            ]
                        )
                )
            , deleteAnswerComment =
                (\tidbitPointer commentID ->
                    apiPost
                        ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteComment/answer")
                        (decode ())
                        (Encode.object [ ( "commentID", Encode.string commentID ) ])
                )
            }
        }


{-| For adding a slash in a URL.
-}
(:/:) : String -> String -> String
(:/:) str1 str2 =
    str1 ++ "/" ++ str2


{-| Converts tidbit pointers to the standard URL format: "<tidbitTypeToInt>/<tidbitID>"
-}
tidbitPointerToUrl : TidbitPointer.TidbitPointer -> String
tidbitPointerToUrl { tidbitType, targetID } =
    (toString <| JSON.TidbitPointer.tidbitTypeToInt tidbitType) :/: targetID
