from google.cloud import firestore

# Initialize Firestore client
db = firestore.Client(project = "kernml")

collection_ref = db.collection('public_minted_nfts')

def find_document_by_field(field_name, field_value):

    # Query to find documents with the specified field and value
    query = collection_ref.where(field_name, '==', field_value).limit(20).stream()

    # Fetching and returning the documents
    return [doc for doc in query]

def delete_documents_with(field_name, field_value):
    query = collection_ref.where(field_name, '==', field_value).limit(20).stream()
    for doc in query:
        doc_id = doc.id
        collection_ref.document(doc_id).delete()
