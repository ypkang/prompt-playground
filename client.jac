import:py streamlit as st;
import:py speech_recognition as sr;

import:jac from server {interact}

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

        # Accept user input
        utterance = st.chat_input("Type to me");
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
                res = root spawn interact(message=utterance, instructions=instructions, session_id="123", chat_history=st.session_state.messages);
                response = res.response;

                # Add user message to chat history
                st.session_state.messages.append({"role": "user", "content": utterance});
                st.session_state.messages.append({"role": "assistant", "content": response});
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