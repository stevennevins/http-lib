// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {HttpLib} from "../src/HttpLib.sol";

contract HttpLibTest is Test {
    using stdJson for string;

    function testGetRequest() public {
        string memory response = HttpLib.get("https://example-data.draftbit.com/products?_limit=1");
        emit log_string(response);
    }

    function testPostRequest() public {
        string memory data = '{"name":"New Product","description":"A test product"}';
        string memory response = HttpLib.post("https://example-data.draftbit.com/products", data);
        emit log_string(response);
    }

    function testGetRequestWithHeaders() public {
        string[] memory headers = new string[](1);
        headers[0] = "Accept: application/json";

        string memory response =
            HttpLib.getWithHeaders("https://example-data.draftbit.com/products?_limit=1", headers);
        emit log_string(response);
    }

    function testPostRequestWithHeaders() public {
        string memory data = '{"name":"New Product","description":"A test product"}';

        string[] memory headers = new string[](1);
        headers[0] = "Content-Type: application/json";

        string memory response =
            HttpLib.postWithHeaders("https://example-data.draftbit.com/products", data, headers);
        emit log_string(response);
    }

    function testParseJsonResponse() public {
        string memory response = HttpLib.get("https://example-data.draftbit.com/products?_limit=1");
        string memory productName = response.readString("$[0].name");
        emit log_string(productName);
    }
}
