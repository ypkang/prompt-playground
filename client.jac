import:py streamlit as st;
import:py os;
import:py speech_recognition as sr;
import:py from audio_recorder_streamlit {audio_recorder}
import:py whisper;
import:py openai;
import:py from helpers {speech_to_text, text_to_speech, autoplay_audio}
import:py streamlit_float;

import:jac from server {interact}

can bootstrap_frontend (token:str = "") {
    openai_client = openai.OpenAI();

    st.set_page_config(layout="wide");

    with st.sidebar {
        st.header("Instructions", anchor=None);
        instructions = st.text_area("Instructions", height=300);
        st.session_state.instructions = instructions;
    }

    with st.container() {
        st.markdown(
            """
            <style>
            [data-testid="stAppViewContainer"]{
                    background-image: url('https://github.com/ypkang/prompt-playground/blob/main/asset/app-bg.png?raw=true');
                    background-size: cover;
                    background-position: center;
            }
            """,
            unsafe_allow_html=True,
        );


        # Initialize chat history
        if "messages" not in st.session_state {
            st.session_state.messages = [];
        }
        # Create footer container for the microphone
        footer_container = st.container();
        with footer_container {
            audio_value = audio_recorder(text="");
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
            }
        }
    }
}

with entry {
    bootstrap_frontend();
}