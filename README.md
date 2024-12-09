### To update with new changes (only need to run this if there have been an update)
Open a new terminal and then run the following
```bash
cd prompt-playground
git pull
source venv/bin/activate
pip install -r requirements.txt
```

### To run the app
Open a new terminal and then run the following
```bash
cd prompt-playground
source venv/bin/activate
jac streamlit client.jac
```