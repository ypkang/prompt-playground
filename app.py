import streamlit as st
import openai
import pyttsx3
import speech_recognition as sr

# Set your OpenAI API key
openai.api_key = "YOUR_OPENAI_API_KEY"

# Initialize text-to-speech engine
engine = pyttsx3.init()


def transcribe_audio(audio_file):
    """Transcribes audio using OpenAI's Whisper API."""
    audio_file.rewind()
    audio_bytes = audio_file.read()

    transcript = openai.Audio.transcribe("whisper-1", audio_bytes)
    return transcript["text"]


def process_text(text):
    """Processes the transcribed text (replace with your desired logic)."""
    # Replace this with your actual processing logic
    processed_text = f"You said: {text}. Here's a response: Hi there!"
    return processed_text


def speak_text(text):
    """Speaks the given text."""
    engine.say(text)
    engine.runAndWait()


def main():
    st.title("Real-Time Speech-to-Text and Text-to-Speech")

    if "recording" not in st.session_state:
        st.session_state["recording"] = False

    def toggle_recording():
        st.session_state["recording"] = not st.session_state["recording"]

    st.button("Start/Stop Recording", on_click=toggle_recording)

    if st.session_state["recording"]:
        with sr.Microphone() as source:
            audio_recorder = sr.Recognizer()
            audio = audio_recorder.listen(source)

            try:
                transcript = transcribe_audio(audio)
                st.write(f"You said: {transcript}")
                processed_text = process_text(transcript)
                speak_text(processed_text)
            except sr.UnknownValueError:
                st.write("Could not understand audio")
            except sr.RequestError as e:
                st.write(f"Error: {e}")


if __name__ == "__main__":
    main()
