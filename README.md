# Environment Setup and Testing Notes

This document summarizes recent work on setting up and testing components of the environment, specifically addressing dependencies related to smart cards and subscriber provisioning.

## Smart Card Dependency Mock

The script `scripts/enhanced_ota_client.py` has a dependency on a smart card reader and the PC/SC service via the `smartcard` Python library. To allow this script to run in environments without a physical smart card setup, a mock smart card layer has been implemented.

-   **Problem:** Running `scripts/enhanced_ota_client.py` directly resulted in `EstablishContextException` or `ModuleNotFoundError` if the `smartcard` library was not fully functional or installed with PC/SC support.
-   **Solution:** The file `scripts/mock_smartcard.py` was created/modified to mock the necessary components of the `smartcard` library, including `smartcard.System.readers` and `smartcard.util.toHexString`.
-   **Result:** By ensuring `scripts/mock_smartcard.py` is present and potentially imported or available in the Python path when running `enhanced_ota_client.py`, the script can execute and utilize the mocked smart card functionality, allowing development and testing without a physical reader.

## Subscriber Setup Script (`scripts/setup-subscriber.sh`)

The script `scripts/setup-subscriber.sh` is used to provision subscribers into the Open5GS MongoDB database.

-   **Purpose:** Adds subscriber information (IMSI, MSISDN, security keys, etc.) to the database required by the core network components.
-   **Dependency:** Requires access to a running MongoDB instance, expected to be available at the hostname `ota-mongodb` on port `27017`.
-   **Workflow:**
    1.  **Start the Network:** The network environment, including the `ota-mongodb` service, must be running. This is typically done using `scripts/start_network.sh` or `docker-compose up`.
    2.  **Execute within Docker:** The `setup-subscriber.sh` script needs to be executed *inside* the `ota-testing-env` Docker container. This container is part of the same Docker network as `ota-mongodb`, allowing the hostname to be resolved correctly. Running the script directly on the host system will result in a `MongoNetworkError` because `ota-mongodb` is not resolvable outside the Docker network.
-   **Execution Command (inside Docker):**
    ```bash
    docker exec ota-testing-env /ota-testing/scripts/setup-subscriber.sh <IMSI> <MSISDN>
    ```
    Replace `<IMSI>` and `<MSISDN>` with the desired subscriber identifiers.

By following these steps, you can successfully run the `enhanced_ota_client.py` script using the mock smart card layer and provision subscribers using `scripts/setup-subscriber.sh` within the correct Docker environment.
