import:py streamlit as st;
import:py os;
import:py speech_recognition as sr;
import:py from audio_recorder_streamlit {audio_recorder}
import:py whisper;
import:py openai;
import:py from helpers {speech_to_text, text_to_speech, autoplay_audio}
import:py streamlit_float;

import:jac from server {interact}


# can transcribe_audo(audio_chunk) {
#     :g: model;
#     result = model.transcribe(audio_chunk);
#     return result["text"];
# }
# 
# can openai_text_to_speech(text) {
#     response = openai.Audio.synthesize(
#         input=text,
#         voice="davinci",
#         model="whisper"
#     );
#     return response["audio"];
# }
# 
# ::py::
# def process_audio(frame):
#     audio_data = frame.to_ndarray()
#     transcription = transcribe_audio(audio_data)
# 
#     # Chatbot logic (replace with your chatbot's API or logic)
#     chatbot_response = f"You said: {transcription}. Here's my response."
# 
#     # Convert response to audio using OpenAI TTS
#     audio_response = openai_text_to_speech(chatbot_response)
# 
#     # Return transcription and audio response
#     return transcription, audio_response
# ::py::




# Function to recognize speech from the microphone
can recognize_speech(col2: `any) {
    r = sr.Recognizer();
    with sr.Microphone() as source {
        col2.info("Listening...");
        audio = r.listen(source);
        col2.info("Recognizing...");
        try {
            # Use Google Web Speech API
            speech_text = r.recognize_google(audio);
            return speech_text;
        } except sr.UnknownValueError {
            return "Sorry, I could not understand the audio.";
        } except sr.RequestError {
            return "Could not request results from Google Speech Recognition service.";
        }
    }
}

can bootstrap_frontend (token:str = "") {
    openai_client = openai.OpenAI();

    st.set_page_config(layout="wide");
    (col1, col2) = st.columns([1, 2]);

    with col1 {
        st.header("Instructions", anchor=None);
        instructions = col1.text_area("Instructions", height=300);
        st.session_state.instructions = instructions;
    }

    with col2 {
        st.header("Chat", anchor=None);
        # Initialize chat history
        if "messages" not in st.session_state {
            st.session_state.messages = [];
        }
        # Create footer container for the microphone
        footer_container = st.container();
        with footer_container {
            audio_value = audio_recorder();
        }


        # audio_value = st.audio_input("speak to me");
        if audio_value {
            with st.spinner("Listening...") {
                webm_file_path = "temp_audio.mp3";
                with open(webm_file_path, "wb") as f {
                    f.write(audio_value);
                }

                transcript = speech_to_text(webm_file_path);
                if transcript {
                    speech_utterance = transcript;
                    os.remove(webm_file_path);
                }
            }
        }

        # Accept user input
        text_utterance = st.chat_input("Type to me");

        utterance = speech_utterance if audio_value else text_utterance;

        if utterance {
            st.session_state.utterance = utterance;
        }

        # Display chat messages from history on app rerun
        for message in st.session_state.messages {
            with st.chat_message(message["role"]) {
                st.markdown(message["content"]);
            }
        }

        # Microphone mode
        # if st.button("Talk to me") {
        #     utterance = recognize_speech(st);
        #     st.session_state.utterance = utterance;
        # }

        if utterance {
            # Display user message in chat message container
            with st.chat_message("user") {
                st.markdown(utterance);
            }

            # Display assistant response in chat message container
            with st.chat_message("assistant") {
                # call walker
                res = root spawn interact(message=utterance, instructions=st.session_state.instructions, session_id="123", chat_history=st.session_state.messages);
                response = res.response;

                # Add user message to chat history
                st.session_state.messages.append({"role": "user", "content": utterance});
                st.session_state.messages.append({"role": "assistant", "content": response});

                with st.spinner("Answering...") {
                    audio_file = text_to_speech(response);
                    autoplay_audio(audio_file);
                    os.remove(audio_file);
                }
                st.write(response);


                # Call walker api
                # response = requests.post("http://localhost:8000/walker/interact", json={"message": prompt, "session_id": "123"},
                #     headers={"Authorization": f"Bearer {token}"}
                # );

                # if response.status_code == 200 {
                #     response = response.json();
                #     print(response);
                #     st.write(response["reports"][0]["response"]);

                #     # Add assistant response to chat history
                #     st.session_state.messages.append({"role": "assistant", "content": response["reports"][0]["response"]});
                # }

            }

        }
    }
}

with entry {
    # INSTANCE_URL = "http://localhost:8000";
    # TEST_USER_EMAIL = "test@mail.com";
    # TEST_USER_PASSWORD = "password";

    # response = requests.post(
    #     f"{INSTANCE_URL}/user/login",
    #     json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    # );

    # if response.status_code != 200 {
    #     # Try registering the user if login fails
    #     response = requests.post(
    #         f"{INSTANCE_URL}/user/register",
    #         json={
    #             "email": TEST_USER_EMAIL,
    #             "password": TEST_USER_PASSWORD
    #         }
    #     );
    #     assert response.status_code == 201;
    #     
    #     response = requests.post(
    #         f"{INSTANCE_URL}/user/login",
    #         json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    #     );
    #     assert response.status_code == 200;
    # }

    # token = response.json()["token"];

    # print("Token:", token);

    bootstrap_frontend();
}