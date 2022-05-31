/**
 *Submitted for verification at FtmScan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EasyAvatarsSVG {
    string[19] public skinToneNames = [
        "Pale Ivory",
        "Warm Ivory",
        "Sand",
        "Rose Beige",
        "Limestone",
        "Beige",
        "Sienna",
        "Amber",
        "Honey",
        "Band",
        "Almond",
        "Bronze",
        "Umber",
        "Golden",
        "Espresso",
        "Chocolate",
        "Invisible",
        "Alien",
        "Zombie"
    ];
    string[19] public skinToneLayers = [
        "#fee3c6",
        "#fde7ad",
        "#f8d998",
        "#f9d4a0",
        "#ecc091",
        "#f2c280",
        "#d49e7a",
        "#bb6536",
        "#cf965f",
        "#ad8a60",
        "#935f37",
        "#733f17",
        "#b26644",
        "#7f4422",
        "#5f3310",
        "#291709",
        "",
        '<path fill="#5a9349" d="M4 4h22v22H4z"/><path stroke="#5a9349" d="M7 1.5h1m0 0h1m12 0h2m-15 1h1m12 1h1m-1-1h1m-14 1h1"/>',
        '<path fill="#698362" d="M4 4h22v22H4z"/><path d="M14 4.5h1m5 0h1m2 0h2m-8 1h1m-1 1h1m3 0h1m1 0h1m-1 1h1m-7 1h1m5 0h1m-1 2h1m-1 2h1m-1 1h1m-9-9h1m1 0h1m1 0h1m2 0h1m-7 1h1m3 0h4m-4 1h1m4 0h1m-9 1h1m1 0h1m1 0h1m2 0h1m-1 1h1m-2 1h1m-1 2h1m-8-7h1m8 0h1m-7 1h1m5 0h1m-10 1h1m2 0h1m2 0h1m-7 1h1m8 0h1m-8-3h1m-4 1h1m2 0h1m5 0h1m-1 1h1m-1 3h1m-4-5h1m-5 5h1" stroke="#b61d1d"/>'
    ];

    string[16] public eyeColorNames = [
        "Black",
        "Light Brown",
        "Dark Brown",
        "Prussian Blue",
        "Blue Sapphire",
        "Teal Blue",
        "Rackley",
        "Moonstone Blue",
        "Beau Blue",
        "Wageningen Green",
        "Light Green",
        "Green",
        "Emerald Green",
        "Traditional Forest Green",
        "Alien",
        "Vampire"
    ];
    string[16] public eyeColorLayers = [
        "#000", // Black
        "#603101",
        "#451800", // Browns
        "#0f305b",
        "#1b5675",
        "#357388",
        "#528c9e",
        "#7fb4be",
        "#b8d8e1", // Blues
        "#25a22b",
        "#03920c",
        "#017101",
        "#035104",
        "#004200", // Greens
        "#0CFB8B",
        "#e70303"
    ];

    string[10] public glassesNames = [
        "None",
        "Rectangular Glasses",
        "Round Glasses",
        "Sun Glasses",
        "Futuristic Glasses",
        "Eye Patch",
        "Steampunk Glasses",
        "3D Glasses",
        "VR Headset",
        "EasyBlock Glasses"
    ];
    string[10] public glassesLayers = [
        "",
        '<path stroke="#000" d="M6 8.5h1m4 0h2m7 0h1m-15 5h1m16 0h1m-13 1h1m-5-6h1m14 0h1m-10 1h1m-4 5h1m8 0h1m-12-6h2m13 2h1m0 1h1m-13 1h1m-3-4h1m7 0h2m1 0h1m1 0h1m-18 1h1m5 0h1m1 0h1m1 0h2m-6 1h1m4 0h1m-14 1h3m10 0h1m5 0h1m1 0h1m-20 1h1m16 0h1m-18 2h2m4 0h1m4 0h2m1 0h3m-6-6h1m-3 1h1m7 0h1m-18 1h1m5 1h1m4 1h1m-6 1h1m4 0h1m-10 1h2m13 0h1"/>',
        '<path stroke="#000" d="M8 8.5h1m11 0h1m-16 3h1m11 0h1m5 0h1m-7 1h1m5 0h1m-13 1h1m-4 1h1m0-6h1m1 1h1m6 0h1m-13 1h1m10 0h1m-12 1h1m5 0h1m-7 1h1m3-4h1m10 0h1m-15 1h1m4 1h1m0 1h4m7 0h2m-14 1h1m-6 1h1m10 0h1m-10 1h1m10 0h1m-2-6h1m2 1h1m-19 2h1m17 2h1m-13 1h1m8 0h1m3-4h1m-3 4h1"/>',
        '<path stroke="#9c1a00" d="M6 8.5h1m2 0h2m6 0h1m3 0h1m-10 2h2m3 0h1m5 0h1m-19 1h1m11 0h1m5 0h1m-18 1h1m-1 1h1m16 0h1m-18 1h3m1 0h3m9 0h2m-17-6h1m11 0h1m2 0h1m-7 2h1m-13 1h1m20 0h1m-7 3h1m-12-6h1m9 0h1m-13 1h1m5 0h1m-1 4h1m4 1h1m-7-6h1m8 0h1m-4 1h1m5 0h1m-10 1h1m-3 1h1m4 1h1m5 0h1m-7 1h1m0 1h1m1 0h1m-9-6h1m10 0h1m-18 2h1m8 0h1m-10 1h1m17 0h1m-13 1h1m-4 2h1m11 0h1"/><path stroke="#4f4f4f" d="M7 9.5h1m2 0h1m11 0h1m-16 1h1m2 0h1m11 0h1m-1 1h1m-13 1h1m-4 1h1m2 0h1m8 0h1m2 0h1m-15-4h1m11 3h1m-12-3h1m8 0h2m-11 1h1m1 0h1m7 0h1m-13 1h1m1 0h2m7 0h3m-14 1h1m1 0h1m1 0h1m6 0h2m1 0h2m-14 1h1m8 0h1m1 0h1m-10-4h1m8 0h2m-14 1h1m11 0h1m-13 1h1m2 0h1m-4 1h1m2 1h1m6-3h1m2 0h1m-1 1h1m-14 2h1m12 0h1"/>',
        '<path stroke="#c0c1c0" d="M4 8.5h1m2 0h1m2 0h1m2 0h1m8 0h1m-19 6h1m2 0h1m8 0h1m5 0h1m-18-6h1m2 0h1m3 0h1m4 0h1m2 0h1m2 0h1m-1 3h1m-7 1h1m5 0h1m-1 1h1m-4 1h1m2 0h1m-18-6h1m2 0h1m8 0h1m-2 1h1m-12 5h1m1 0h1m3 0h1m11 0h1m-14-6h1m2 0h3m2 0h1m1 0h1m2 0h2m-3 1h1m-7 1h1m-1 1h1m-1 2h1m-13 1h1m3 0h2m2 0h3m1 0h3m1 0h1m3 0h1m-3-4h1m-13 4h1"/><path stroke="#6ac2e6" d="M4 9.5h1m5 0h1m2 0h1m-7 1h1m2 0h1m2 0h1m11 0h1m-22 1h1m2 0h1m2 0h1m2 0h1m-7 1h1m2 0h1m5 0h1m8 0h1m-16 1h1m14 0h1m-21-4h2m1 0h1m2 0h1m2 0h1m-10 1h1m3 0h1m4 0h1m-10 1h1m2 0h1m0 1h1m5 0h1m-11 1h1m1-4h1m4 0h1m2 0h2m7 0h2m-22 1h1m1 0h1m1 0h1m2 0h2m3 0h1m-8 1h1m1 0h2m1 0h1m1 0h1m8 0h1m-22 1h1m3 0h1m3 0h3m9 0h1m-21 1h1m2 0h2m2 0h4m1 0h1m-8-4h1m14 1h1m-19 1h1m8 0h1m8 0h1m-20 1h2m-1 1h1m2 0h1m5 0h1m8 0h1m-10-3h1m-5 2h1"/>',
        '<path stroke="#000" d="M25 6.5h1m-1 1h1m-10 1h1m2 0h1m2 2h1m-4 1h1m2 0h1m-7 1h1m2 0h1m2 0h1m-4 1h1m-7 1h1m-4 1h1m-1 1h1m-7 3h1m19-12h1m-7 1h1m5 1h1m-7 1h1m4 0h1m-4 1h1m-3 1h1m-4 1h1m-2 1h1m-9 3h1m10-9h1m2 0h1m1 0h3m-9 1h8m-7 1h1m1 0h3m-4 1h1m2 0h1m-5 1h1m3 0h1m-8 1h1m1 0h1m3 0h1m-1 1h1m-10 1h1m-5 2h1m-4 1h1m16-10h1m-2 4h1m-9 3h1m-5 1h1m-1 1h1m-4 1h2m14-5h1m-10 1h1m-4 2h1"/>',
        '<path stroke="#422616" d="M8 8.5h1m11 0h1m-9 3h1m10 1h1m-16 2h1m11 0h1m-12-6h2m8 0h1m1 0h1m-11 1h1m5 1h1m5 0h1m-1 1h1m-18 1h1m10 0h1m-7 1h1m-2 1h1m8 0h1m-13-5h1m14 0h1m-16 4h1m14 0h1m-5-4h1m-7 1h1m-7 1h1m10 0h1m-12-1h1m5 2h1m5 1h1m-10 1h1m11 0h1"/><path stroke="#4f4f4f" d="M8 9.5h3m10 0h1m-14 1h1m1 0h2m7 0h1m1 0h2m-14 1h3m10 0h1m-14 1h1m1 0h1m7 0h1m1 0h1m-3 1h1m-1-4h1m-13 1h1m-1 1h1m11 0h1m-13 1h1m2 0h1m11 0h1m-13 1h1m9-4h1m-3 2h1m-11 1h1m0 1h1m10 0h2m-13-3h1m8 0h1m1 0h1m-13 1h1m11 0h2m-2 1h1m-13 1h1m0-3h1m8 0h1m1 0h1m-13 1h1m11 0h2m-2 1h1m-13 1h1m9-1h1"/><path stroke="#000" d="M13 10.5h1m2 1h1m-13 1h1m8 0h1m11 0h1m-21 0h1m-2-2h1m9 0h3m8 0h1m-13 1h1m1 0h1m-1 1h2m-12-2h1m18 0h1m-11 1h1m-1 1h1m9 0h1"/>',
        '<path stroke="#8c8d8c" d="M6 8.5h1m1 0h1m8 0h1m2 0h2m-5 2h1m-13 1h2m10 0h1m5 0h1m-1 2h1m-13 1h1m8 0h1m2 0h1m-17-6h1m2 0h2m7 0h1m2 0h2m-18 1h1m16 0h1m-9 1h2m7 1h2m-20 1h1m5 0h1m10 0h1m-7 1h1m-11 1h1m1 0h2m1 0h1m4 0h3m1 0h1m-13-6h1m2 0h1m5 0h1m-7 1h1m-7 1h1m5 0h1m1 0h1m8 0h1m-12 1h1m-7 2h1m5 0h1m-5 1h1m8-5h1m-1 3h1m-12 2h1m6-4h1m-10 1h1m17 3h1"/><path stroke="#ea473f" d="M18 9.5h1m2 0h1m-4 2h1m2 1h1m-1 1h1m-3-4h1m2 0h1m-1 1h1m-4 1h1m2 0h1m-4 1h1m2 0h1m-3-3h1m-3 1h4m-4 2h1m0 1h2m1 0h1m-3-2h1m-1 1h1m-3 1h1m2-2h1"/><path stroke="#498dcd" d="M7 11.5h1m2 0h1m-1 1h1m-1 1h1m-2-2h1m1 1h1m-3 1h1m-3-4h1m2 0h1m-4 1h2m1 0h1m-3 1h1m-2 1h3m-3 1h1m0-4h2m1 0h1m-3 1h1m1 0h1m-1 1h1m-4 2h1m2 0h1"/>',
        '<path stroke="#8d8d8d" d="M7 7.5h3m1 0h1m1 0h1m3 0h1m3 0h1m2 2h1m-1 2h2m-1 1h1m-21 1h1m1 2h1m1 0h3m6 0h3m1 0h1m-13-8h1m5 0h1m2 0h1m2 0h1m-19 3h1m20 0h1m-22 1h1m-1 1h1m8 3h1m2 0h1m-5-8h1m5 0h1m1 0h1m-16 3h1m-1 2h1m18 0h1m-1 1h1m-11-6h1m-10 2h1m18 1h1m-20 1h1m2 4h1m5 0h1m2 0h1m-3-8h1m-4 8h1m2 0h1m5 0h1"/><path stroke="#000" d="M6 8.5h1m16 0h1m-15 1h1m2 0h1m2 0h1m1 0h2m2 0h1m-8 1h1m6 0h1m-10 1h1m2 0h1m2 0h1m2 0h1m-13 1h1m8 0h1m-8 1h2m2 0h1m-10 1h1m4-5h1m2 0h1m2 1h1m-4 1h1m2 0h1m2 0h1m-9 1h1m2 0h1m1 0h1m-10 1h1m5 0h1m2 0h1m4-5h1m-16 1h2m1 0h1m2 0h1m2 0h1m5 0h1m-15 1h1m2 0h2m2 0h1m2 0h1m1 0h1m-13 1h2m1 0h1m1 0h1m-6 1h1m2 0h1m1 0h1m2 0h1m3 0h2m-12 1h1m5 0h1m4 0h1m-15 1h1m14 0h2m-4-5h1m-12 1h1m4 2h1m-6 1h1m8 0h1m1 0h1m-14-5h1m11 1h1m-10 1h1m2 0h1m2 0h1m2 0h1m-10 1h1m5 0h1m2 0h1m-10 1h1m8 0h1m-13 1h1m5 0h1m5 0h1m2 0h1"/><path stroke="#b5b4b5" d="M8 8.5h1m-3 2h1m-1 1h1m2 3h1m2 0h1m-4-6h1m1 0h1m5 0h2m2 0h1m1 4h1m-18 1h1m7 1h1m2 0h1m-8-6h1m8 0h1m-13 2h1m-1 2h1m5 2h1m5 0h1m-8-6h5m3 0h1m-15 1h1m16 0h1m-2 1h2m-17 1h1m14 0h2m-2 1h1m0 1h1m-16 1h1m1 0h2m3 0h2m1 0h1m1 0h2m-16-2h1"/>',
        '<path stroke="#000" d="M6 8.5h1m2 0h1m13 1h1m-18 1h1m2 0h1m11 1h1m1 0h1m-12 1h1m8 0h1m-16 1h1m5 0h1m4 0h1m-12 1h1m1 0h1m3 0h1m5 0h1m2 0h1m-15-6h2m3 0h1m6 0h3m1 0h1m-18 1h1m5 0h1m8 0h1m-12 1h1m1 0h1m2 0h3m1 0h1m1 0h1m-18 1h3m3 0h1m1 0h1m4 0h1m-10 1h2m1 0h1m8 0h1m2 0h1m-16 1h1m10 0h1m-13 1h1m2 0h1m6 0h1m4 0h1m-13-6h1m11 0h1m-13 1h1m-4 1h1m5 0h1m5 1h1m5 0h1m-16 1h1m8 0h1m2 0h1m-4 2h1m-9-6h1m5 0h2m-2 1h1m-10 1h1m5 0h1m3 0h1m1 0h1m2 0h1m-16 1h1m-3 1h1m10 0h1m5 1h1m-13 1h1m8 0h1m2 0h1m0-3h1m-16 3h1"/><path stroke="#fff" d="M7 9.5h1m0 0h2m8 3h1m-1-3h1m0 0h1m-13 2h1m-1 1h1m-1 1h1m10 0h1m1-4h1m-3 2h1"/><path stroke="#3f68a4" d="M11 9.5h1m-1 1h1m-3 3h1m0 0h1m0 0h1m-1-2h1"/><path stroke="#3b72ea" d="M9 11.5h1"/><path stroke="#ef763a" d="M20 11.5h1"/><path stroke="#eb5133" d="M20 13.5h1m0 0h1m0-4h1m-1 4h1m-1-3h1m-1 1h1"/>'
    ];

    string[8] public mouthNames = [
        "Normal",
        "Smile",
        "Unhappy",
        "Ooo",
        "Moustache",
        "Fancy Moustache",
        "Zombie",
        "Vampire"
    ];
    string[8] public mouthLayers = [
        '<path fill="#000" d="M10 20h10v1H10z"/>',
        '<path stroke="#000" d="M9 18.5h1m8 1h1m-7 1h1m4 0h1m-8-2h1m8 0h1m-7 2h1m2 0h1m3-2h1m-11 1h2m7 0h1m-2 1h1m-8 0h1m2 0h1m0 0h1"/>',
        '<path stroke="#000" d="M11 20.5h1m5 0h1m-6 0h1m2 0h1m2 0h1m-1 1h1m-6-1h1m2 0h1m2 1h1m-1 1h1m-6-2h1m-5 1h2m-2 1h1"/>',
        '<path stroke="#000" d="M13 17.5h4m-5 1h1m4 0h1m-1 1h2m-1 1h1m-7 2h2m-1 1h1m1 0h1m-3-5h1m2 0h1m-1 4h1m-1 1h1m-6-4h1m-1 1h1m2 3h1m-3-4h1m4 2h2m-8 0h2m4 1h1"/>',
        '<path stroke="#9f6f39" d="M9 19.5h3m1 0h2m2 0h1m2 1h1m0 1h1m-1 1h1m-10-3h1m2 0h1m-7 1h1m10 1h1m-5-2h1m2 0h1m-2 0h1m1 0h1m-13 1h1m12 0h1m-14 1h2m-2 1h1"/><path stroke="#000" d="M10 20.5h2m4 0h1m2 0h1m-8 0h1m0 0h1m0 0h1m3 0h1m-4 0h1m1 0h1"/>',
        '<path stroke="#bb8951" d="M8 16.5h1m12 0h1"/><path stroke="#9f6f38" d="M9 16.5h1m8 3h1m-9-3h1m8 0h1m-10 3h1m2 0h1m2 0h1m2 0h1m0-3h1m-3 1h1m2 0h1m-1 1h1m-8 1h1m2 0h1m-10-2h1m2 0h1m-4 1h1m0 1h1m1 0h1m3 0h1m4 0h1m-9 0h1"/><path stroke="#000" d="M10 20.5h1m8 0h1m-9 0h1m5 0h1m-6 0h1m5 0h1m-6 0h1m2 0h1m-3 0h2"/>',
        '<path stroke="#b71c1d" d="M9 19.5h1m8 0h1m1 0h1m-11 0h1m8 0h1m-4 2h1m0 4h1m-7-6h2m7 1h1m-7 1h1m2 0h1m-5-2h1m2 0h2m-9 1h1m-1 1h1m1 0h1m1 0h1m1 0h1m3 0h2m-6 1h2m0 4h1m-4-7h2m-4 2h1m5 0h1m-2 1h2m-9-1h1m5 2h1m-1 1h2m-3-1h1m1 0h1"/><path stroke="#000" d="M10 20.5h5m1 0h1m-2 0h1m2 0h1m-2 0h1m1 0h1"/>',
        '<path stroke="#000" d="M10 20.5h4m1 0h1m2 0h2m-6 0h1m2 0h1m-2 0h1"/><path stroke="#b71c1c" d="M10 21.5h1m0 0h1m-1 1h1m-1 1h1m0 1h1m-1 2h1m-1-4h1m-1 1h1m-1 2h1"/><path stroke="#bababa" d="M12 21.5h1m4 0h1m-1 1h1m-1 1h1"/>'
    ];

    string[4] public mouthPieceNames = ["None", "Vape", "Cigar", "420"];
    string[4] public mouthPieceLayers = [
        "",
        '<path stroke="#000" d="M16 19.5h1m2 0h1m2 0h1m2 0h1m-10 2h1m2 0h1m-3-2h2m2 0h1m1 0h2m1 0h2m-13 1h1m12 0h1m-9 1h1m1 0h4m-9 0h1m3 0h1m-4 0h1m8 0h1m-8-2h1m5 2h1"/><path stroke="#8d8d8d" d="M16 20.5h2m2 0h2m2 0h1m-7 0h1m0 0h1m2 0h1m2 0h1m-3 0h1m2 0h1"/><path stroke="#064af4" d="M27 20.5h1"/>',
        '<path stroke="#a6a6a7" d="M27 9.5h1m0 2h1m-2 1h1m-1 1h2m-2 2h2m-1 1h1m-2 1h1m0 1h1m-2-8h1m-1 1h1m-1 3h1m-1 2h1m0-4h1m-1 2h1m-1 3h1"/><path stroke="#000" d="M15 18.5h1m2 0h3m1 0h1m1 0h1m-11 1h1m13 0h1m-1 2h1m-13 1h1m2 0h2m1 0h1m-7-4h1m8 0h1m2 2h1m-4 2h1m-9-4h1m9 0h1m-14 2h1m0 2h1m10 0h1m-6-4h1m-4 4h1m2 0h1m2 0h1m2 0h1m-5-4h1m2 0h1m-13 3h1m2 1h1m5 0h1"/><path stroke="#261711" d="M15 19.5h1m2 0h2m1 0h1m1 0h4m-11 1h2m1 0h3m3 0h2m-12 1h2m1 0h2m2 0h4m-10-2h1m5 0h1m-1 1h1m-6-1h1m2 0h1m-6 1h1m5 1h1m-4-1h1m4 0h2m-8 1h1m2 0h1m5 0h1"/><path stroke="#f27f02" d="M27 19.5h1m-1 1h1m-1 1h1"/>',
        '<path stroke="#a6a6a7" d="M27 12.5h1m-1 1h1m-1 3h1m-1 2h1m-1-4h1m-1 3h1m-1-2h1"/><path stroke="#000" d="M16 19.5h1m2 0h2m1 0h1m1 0h2m-11 1h1m0 1h2m5 0h1m3 0h1m-11-2h1m5 0h1m2 0h1m-7 2h1m5 0h1m-9-2h1m5 2h1m-4-2h1m5 0h1m-10 2h1m2 0h1m6-1h1m-10 1h1m2 0h1m2 0h1"/><path stroke="#caae98" d="M16 20.5h1m2 0h1m2 0h1m-6 0h1m3 0h1m2 0h2m-8 0h1m1 0h1m2 0h1m2 0h1"/><path stroke="#f27e02" d="M27 20.5h1"/>'
    ];
}