import:py from mtllm.llms {OpenAI}
# import:jac from rag {rag_engine}

glob llm = OpenAI(model_name='gpt-4o-mini');
# glob RagEngine:rag_engine = rag_engine();

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
        ) -> 'response':str by llm();

        here.response = respond_with_llm(
            message=here.message,
            instructions=here.instructions,
            #learning_concepts=here.learning_concepts,
            chat_history=here.chat_history
        );
    }
}