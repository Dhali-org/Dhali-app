from firestore_utils import find_document_by_field
from firestore_utils import delete_documents_with


def test_clean_up():
    name = "integration-test-api"
    documents = find_document_by_field('name', name)
    for doc in documents:
        # The amount specified in the integration test
        assert(doc.to_dict()["asset_earning_rate"] == 12000.0)
        # The earning type specified in the integration test
        assert(doc.to_dict()["asset_earning_type"] == "per_request")
    delete_documents_with('name', name)
    print(documents)
