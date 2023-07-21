//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155 {
    function safeTransformFrom(address from, address to, uint id, uint value, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256 value, bytes calldata data) external;

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC1155TokenReceiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4); 

    function onIERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4);
}

contract ERC1155 is IERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    // Mapping owner => id => balance
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    // Mapping owner => id => balance 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function safeTransformFrom(address from, address to, uint id, uint value, bytes calldata data) external {}

    function safeBatchTransferFrom(address from, address to, uint256 value, bytes calldata data) external {}

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory) {}

    function setApprovalForAll(address operator, bool approved) external {}

    //Tell other contracts that it supports the following interfaces
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || //ERC165
             interfaceId == 0xd9b67a26 || //ERC1155
             interfaceId == 0x0e89341c; //ERC1155 MetadataURI
    }

    // Mint not part of ERC1155 standard, make it internal using _
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal {
        // Update balance of to for tokenid, if to is a contract we call callback
        require(to != address(0), "address cannot be a zero address");

        //update balance of owner. owner => id => balance
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender,address(0), to, id, value);
        
        // Call callback if to address is a contract, cannot 
        if(to.code.length > 0){
            require (IERC1155TokenReceiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                value,
                data
            ) == IERC1155TokenReceiver.onERC1155Received.selector, "unsafe transfer to a contract address");
        }
    }

    function _batchMint(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) internal {
        // Require to is not a zero address
        require(to != address(0), "address to cannot be a zero address");
        require(ids.length == values.length, "ids length != values length");
        
        // Mint multiple tokens inside
        for(uint  i = 0; i < ids.length; i++){
            balanceOf[to][ids[i]] += values[i];
        }

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        // Call callback if to address is a contract, cannot 
        if(to.code.length > 0){
            require (IERC1155TokenReceiver(to).onIERC1155BatchReceived(
                msg.sender,
                address(0),
                ids,
                values,
                data
            ) == IERC1155TokenReceiver.onIERC1155BatchReceived.selector, "unsafe transfer to a contract address");
        }
    }

    function _burn(address from, uint256 id, uint256 amount) internal {
         // Update balance of to for tokenid, if to is a contract we call callback
        require(from != address(0), "from address cannot be a zero address");

        //update balance of owner. owner => id => balance
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
        
      
    }

        function _batchBurn(address from, uint256[] calldata ids, uint256[] calldata values) internal {
        // Require to is not a zero address
        require(from != address(0), "from address to cannot be a zero address");
        require(ids.length == values.length, "ids length != values length");
        
        // Mint multiple tokens inside
        for(uint  i = 0; i < ids.length; i++){
            balanceOf[from][ids[i]] -= values[i];
        }

        emit TransferBatch(msg.sender, from, address(0), ids, values);
    }

}
// N/B mint functions are not part of ERC1155
contract MyMultiToken is ERC1155 {

    function mint(uint256 id, uint256 value, bytes memory data) external {
        _mint(msg.sender, id, value, data);
    }

    function batchMint(uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external {
        _batchMint(msg.sender, ids, values, data);
    }

    function burn(uint256 id, uint256 value) external {
        _burn(msg.sender, id, value);
    }

    function batchBurn(uint256[] calldata ids, uint256[] calldata values) external{
        _batchBurn(msg.sender, ids, values);
    }
}



