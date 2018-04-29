module ExplanatoryBlurbs exposing (..)

{-| Explanatory text that is exposed to the user, kept in one module so we can keep the "voice" of the website
consistent.
-}


{-| Used in `AnswerQuestion`.
-}
answerQuestionPlaceholder : String
answerQuestionPlaceholder =
    "Write your answer...\n\n\n"
        ++ markdownExplanatoryText


{-| Used in `EditAnswer`.
-}
editAnswerPlaceholder : String
editAnswerPlaceholder =
    "Edit your answer...\n\n\n"
        ++ markdownExplanatoryText


{-| Used in `EditQuestion`.
-}
editQuestionPlaceholder : String
editQuestionPlaceholder =
    "Edit your question...\n\n\n"
        ++ markdownExplanatoryText


{-| Used in `AskQuestion`.
-}
askQuestionPlaceholder : String
askQuestionPlaceholder =
    "Highlight the code confusing you and ask your question...\n\n\n"
        ++ markdownExplanatoryText


{-| Currently used in Snipbits/Bigbits to explain how to use markdown in the frame placeholders.
-}
markdownFramePlaceholder : Int -> String
markdownFramePlaceholder frameNumber =
    "Frame "
        ++ toString frameNumber
        ++ " Markdown\n\n"
        ++ "Highlight a chunk of code and explain it...\n\n\n"
        ++ markdownExplanatoryText


{-| A quick blurb about how to use markdown.
-}
markdownExplanatoryText : String
markdownExplanatoryText =
    "Markdown Example Usage\n\n"
        ++ "# Biggest Title\n"
        ++ "###### Smallest Title\n\n"
        ++ "[link name](https://google.com)\n\n"
        ++ "*italic text*\n"
        ++ "**bold text**\n\n"
        ++ "```LANGUAGE_NAME\n"
        ++ "...\n"
        ++ "code\n"
        ++ "...\n"
        ++ "```\n\n"
        ++ "> indented text"
