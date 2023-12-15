import requests
import time
from firestore_utils import find_document_by_field
from firestore_utils import collection_ref
import math
import json

from dhali import payment_claim_generator as pcg


wallet = pcg.get_xrpl_wallet()
payment_claim = json.dumps(pcg.get_xrpl_payment_claim(wallet.seed, "rhtfMhppuk5siMi8jvkencnCTyjciArCh7", "10000000", wallet.sequence, "100000000"))


def make_request_and_measure_time(url, headers):
    start_time = time.time()
    response = requests.get(url, headers=headers)
    print(response.status_code)
    end_time = time.time()
    return end_time - start_time

def test_main():
    name = "integration-test-api"
    documents = find_document_by_field("name", name)
    documents[0].id
    url = f"https://dhali-staging-run-3mmgxhct.uc.gateway.dev/{documents[0].id}/xls20-nfts/all/issuers"

    print(url)

    headers = {"Payment-Claim": payment_claim}

    times = []
    number_of_calls = 7
    our_compute_cost_per_ms = 0.1
    our_compute_costs = 0

    for _ in range(number_of_calls):
        elapsed_time = make_request_and_measure_time(url, headers)
        times.append(elapsed_time)
        our_compute_costs += our_compute_cost_per_ms * elapsed_time * 1000        
        print(f"Request Time: {elapsed_time} seconds")

    average_time = sum(times) / len(times)

    asset_earning_rate = 12000.0 # The amount specified in the integration test
    dhali_earnings_rate = 0.05 # The amount specified in public.json
    average_cost = our_compute_costs  / len(times) + asset_earning_rate * (1 + dhali_earnings_rate)
    
    # Wait for nft manager to consolidate
    time.sleep(30)
    udated_document = collection_ref.document(documents[0].id).get()
    print(udated_document.to_dict()["num_successful_requests"], number_of_calls )
    print(udated_document.to_dict()["average_inference_time_ms"], average_time * 1000)
    print(udated_document.to_dict()["average_cost"], average_cost)

    assert udated_document.to_dict()["num_successful_requests"] == number_of_calls

    assert udated_document.to_dict()["average_inference_time_ms"] < average_time * 1000
    assert udated_document.to_dict()["average_cost"] < average_cost * 1000

    assert math.isclose(udated_document.to_dict()["average_inference_time_ms"], average_time * 1000, abs_tol=3000)
    assert math.isclose(udated_document.to_dict()["average_cost"], average_cost, abs_tol=1000)
