# import:jac from rag {rag_engine}
import from mtllm.llms.base { BaseLLM }

# glob RagEngine:rag_engine = rag_engine();

glob SYSTEM_PROMPT: str = "";
glob NORMAL_SUFFIX: str = "";
::py::

class OpenAI(BaseLLM):
    """Anthropic API client for MTLLM."""

    MTLLM_METHOD_PROMPTS: dict[str, str] = {
        "Normal": NORMAL_SUFFIX,
        "Reason": "",
        "Chain-of-Thoughts": "",
        "ReAct": "",
    }
    MTLLM_SYSTEM_PROMPT = SYSTEM_PROMPT
    # MTLLM_PROMPT = PROMPT_TEMPLATE

    def __init__(
        self,
        verbose: bool = False,
        max_tries: int = 10,
        type_check: bool = False,
        **kwargs: dict,
    ) -> None:
        """Initialize the Anthropic API client."""
        import openai  # type: ignore

        super().__init__(verbose, max_tries, type_check)
        self.client = openai.OpenAI()
        self.model_name = str(kwargs.get("model_name", "gpt-4o-mini"))
        self.temperature = kwargs.get("temperature", 0.7)
        self.max_tokens = kwargs.get("max_tokens", 1024)

    def __infer__(self, meaning_in: str | list[dict], **kwargs: dict) -> str:
        """Infer a response from the input meaning."""
        if not isinstance(meaning_in, str):
            assert self.model_name.startswith(
                ("gpt-4o", "gpt-4-turbo")
            ), f"Model {self.model_name} is not multimodal, use a multimodal model instead."
        print(meaning_in)
        messages = [{"role": "user", "content": meaning_in}]
        output = self.client.chat.completions.create(
            model=kwargs.get("model_name", self.model_name),
            temperature=kwargs.get("temperature", self.temperature),
            max_tokens=kwargs.get("max_tokens", self.max_tokens),
            messages=messages,
        )
        return output.choices[0].message.content
::py::


glob llm = OpenAI(model_name="gpt-4o-mini");

walker interact {
    has message: str;
    has session_id: str;
    has instructions: str;
    has chat_history: list[dict];
    
    can init_session with `root entry {
        visit [-->](`?session)(?id == self.session_id) else {
            session_node = here ++> session(id=self.session_id, chat_history=[], status=0);
            visit session_node;
        }
    }
}

node session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 0;

    can chat with interact entry {
        self.chat_history.append({"role": "user", "content": here.message});
        response = infer(message=here.message, chat_history=here.chat_history, instructions=here.instructions) spawn root;
        self.chat_history.append({"role": "assistant", "content": response.response});
        here.response = response.response;

        # report {
        #     "response": response.response
        # };
    }
}

enum ChatType {
    RAG : 'Need to use Retrivable information in specific documents to respond' = "RAG",
    QA : 'Given context is enough for an answer' = "user_qa"
}

# node router {
#     can 'route the query to the appropriate task type'
#     classify(message:'query from the user to be routed.':str) -> ChatType by llm(method="Reason", temperature=0.0);
# }

walker infer {
    has message:str;
    has chat_history: list[dict];
    has instructions: str;

    can init_qa_chat_node with `root entry {
        visit [-->](`?qa_chat) else {
            qa_chat_node = here ++> qa_chat();
            visit qa_chat_node;
        }
    }
    # can init_router with `root entry {
    #     visit [-->](`?router) else {
    #         router_node = here ++> router();
    #         print("Router Node Created");
    #         router_node ++> rag_chat();
    #         router_node ++> qa_chat();
    #         visit router_node;
    #     }
    # }

    # can route with router entry {
    #     classification = here.classify(message = self.message);

    #     print("Classification:", classification);

    #     visit [-->](`?chat)(?chat_type==classification);
    # }
}

node chat {
    has chat_type: ChatType;
}
# 
# node rag_chat :chat: {
#     has chat_type: ChatType = ChatType.RAG;
# 
#     can respond with infer entry {
#         print("Responding to the message");
#         can 'Respond to message using chat_history as context and agent_role as the goal of the agent'
#         respond_with_llm(   message:'current message':str,
#                     chat_history: 'chat history':list[dict],
#                     agent_role:'role of the agent responding':str,
#                     context:'retirved context from documents':list
#                         ) -> 'response':str by llm();
#         data = RagEngine.get_from_chroma(query=here.message);
#         print("Data:", data);
#         here.response = respond_with_llm(here.message, here.chat_history, "You are a conversation agent designed to help users with their queries based on the documents provided", data);
#         print("Here:", here);
#     }
# }

node qa_chat :chat: {
    has chat_type: ChatType = ChatType.QA;

    can respond with infer entry {

        can 'You are a virtual assistant. Respond to the message following the instructions. Taking into consideration the previous chat_history.'
        respond_with_llm(
            message:'current message': str,
            instructions: 'instructions': str,
            chat_history: 'chat history': list[dict],
        ) -> 'response':str by llm(is_custom=True, raw_output=True);

        here.response = respond_with_llm(
            message=here.message,
            instructions=here.instructions,
            #learning_concepts=here.learning_concepts,
            chat_history=here.chat_history
        );
    }
}