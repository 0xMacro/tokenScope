//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/// A nullable boolean.
/// @dev UNSET is at first index so values will initialize as unset.
/// This means that casting directly to bool will not be correct.
enum OptionalBool {
    UNSET,
    FALSE,
    TRUE
}

library OptionalBitMaps {
    using BitMaps for BitMaps.BitMap;

    struct OptionalBitMap {
        BitMaps.BitMap boolBits;
        BitMaps.BitMap isSetBits;
    }

    function _boolToOptionalBool(bool val) private pure returns (OptionalBool) {
        if (val) {
            return OptionalBool.TRUE;
        } else {
            return OptionalBool.FALSE;
        }
    }

    function _optionalBoolToBool(OptionalBool val) private pure returns (bool) {
        if (val == OptionalBool.UNSET) revert("OptionalBitMap:UNSET_VALUE");
        return (val == OptionalBool.TRUE);
    }

    function get(OptionalBitMap storage bitmap, uint256 index)
        internal
        view
        returns (OptionalBool)
    {
        if (bitmap.isSetBits.get(index) == false) {
            /// UNSET flag is true, so return UNSET
            return OptionalBool.UNSET;
        } else {
            /// UNSET flag is false, so return the bool value
            return _boolToOptionalBool(bitmap.boolBits.get(index));
        }
    }

    function setTo(
        OptionalBitMap storage bitmap,
        uint256 index,
        OptionalBool value
    ) internal {
        /// @dev capture present UNSET flag state
        /// so we only update the UNSET bit if necessary
        bool isSet = bitmap.isSetBits.get(index);

        if (value == OptionalBool.UNSET) {
            if (isSet) {
                bitmap.isSetBits.setTo(index, false);
            }
        } else {
            if (!isSet) {
                bitmap.isSetBits.setTo(index, true);
            }
            bitmap.boolBits.setTo(index, _optionalBoolToBool(value));
        }
    }

    function setTo(
        OptionalBitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        setTo(bitmap, index, _boolToOptionalBool(value));
    }

    function setTrue(OptionalBitMap storage bitmap, uint256 index) internal {
        setTo(bitmap, index, OptionalBool.TRUE);
    }

    function setFalse(OptionalBitMap storage bitmap, uint256 index) internal {
        setTo(bitmap, index, OptionalBool.FALSE);
    }

    function setNull(OptionalBitMap storage bitmap, uint256 index) internal {
        setTo(bitmap, index, OptionalBool.UNSET);
    }
}
