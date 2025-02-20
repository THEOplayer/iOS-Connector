# Preplay

This article explains how to leverage the Uplynk Preplay API through THEOplayer. This API allows developers to pre-integrate with Uplynk Preplay service.

Uplynk users can use an API (i.e. Preplay) to generate a streaming playlist given 1 or more assets or advertisements. The back-end of Uplynk stitches the content together and allows for server-side ad-insertion (SSAI) when applicable. This document describes how THEOplayer users should configure their source to leverage this Preplay service.

Assumptions:

- THEOplayer assumes the availability of the Preplay API and Uplynk content servers to be 100%, since these identify and provide the necessary streams for playback with this feature.
- THEOplayer assumes that developers who are interested in this feature have a basic understanding of the Preplay API. Uplynk documents this service at [https://docs.edgecast.com/video/#Develop/Preplayv2.htm](https://docs.edgecast.com/video/#Develop/Preplayv2.htm)
- THEOplayer assumes that developers provide correct asset identifiers, as well as the proper content protection level.

## Stream Configuration (without ads)

The examples below demonstrate how to configure a stream through the Uplynk connector.

We start by creating an `UplynkSSAIConfiguration` object that describes how to configure an Uplynk source. 

```swift
    let ssaiConfiguration = UplynkSSAIConfiguration(
                                id: .asset(ids: [ your list of asset IDs]),
                                assetType: .asset or .channel,
                                prefix: "https://content.uplynk.com", 
                                preplayParameters: [ Dictionary of parameters ]
                                contentProtected: true or false)
```

- `id`: The ID field identifies the asset. Instead of a single string, developers can also specify an array of asset IDs as strings, which will be stitched into a continuous stream. Assets can also be identified by `externalIds` and a `userId`. In that case, you can instantiate a `.channel(ids: [list of channel IDs], userID: your user ID)` instead.
 
- `preplayParameters`: The `preplayParameters` object should have string-key-string-value combinations, which will be used as query parameters for the Preplay API call. Nested objects are not supported.

- `contentProtected`: Boolean value which will internally set any necessary content-protection information. No content-protection details have to be specified by the customer.

- **A Preplay request must include all parameters defined within the playback request, hence these parameters must be included in the THEOplayer source**. This request must also include a digital signature if the 'Require a token for playback' option is enabled in the back-end on the corresponding live channel. (See also : [Signing a Playback URL Tutorial](https://docs.uplynk.com/docs/sign-playback-url))
  
- Uplynk specific documentation on the available playback URL query parameters can be found on the Uplynk documentation site under [Customizing Playback via Parameters](https://docs.uplynk.com/docs/customize-playback-via-parameters)
  
- Some parameters can be excluded from the digital signature calculation. These parameters may enable certain use cases (e.g. DVR) and would for this reason be excluded from the digital signature.


Now, you can create a typed source, and attached 
```swift
// Swift examples

yourTHEOPlayer.source = sourceDescription
```

The snippets above gives a quick overview of the structure of the Verizon Media-specific source, also known as a [VerizonMediaSource](pathname:///theoplayer/v8/api-reference/ios/Classes/VerizonMediaSource.html).
More information on certain properties:

- `id`: The ID field can instead of an asset id as a single string also specify an array of asset ids as strings, which will be stitched into a continuous stream. The same goes for the`externalId`property in case an external ID is used in the source.

- `orderedParameters`: The `orderedParameters` object should have string-key-string-value combinations, which will be used as query parameters for the Preplay API call. Nested objects are not supported.

- `contentProtected`: Boolean value which will internally set any necessary content-protection information. No content-protection details have to be specified by the customer.

- **A Preplay request must include all parameters defined within the playback request, hence these parameters must be included in the THEOplayer source**. This request must also include a digital signature if the 'Require a token for playback' option is enabled in the back-end on the corresponding live channel. (See also : [Signing a Playback URL Tutorial](https://docs.uplynk.com/docs/sign-playback-url))
  
- Uplynk specific documentation on the available playback URL query parameters can be found on the Uplynk documentation site under [Customizing Playback via Parameters](https://docs.uplynk.com/docs/customize-playback-via-parameters)

- Some parameters can be excluded from the digital signature calculation. These parameters may enable certain use cases (e.g. DVR) and would, for this reason, be excluded from the digital signature.

## Stream Configuration (with ads)

The examples below demonstrate how to configure a stream with server-side ads through a [VerizonMediaSource](pathname:///theoplayer/v8/api-reference/web/interfaces/VerizonMediaSource.html).

##### Web SDK

```js
player.source = {
    sources: [{
        integration: 'verizon-media',
        id: ['verizonMedia_content_first', 'verizonMedia_ad_break_1', 'verizonMedia_content_middle', 'verizonMedia_ad_break_2', 'verizonMedia_content_last'],
        preplayParameters: {
            // Parameters here should specify the necessary ad parameters for the Preplay API
            ad.param1: 'param_val1',
            ad.param2: 'param_val2'
        },
    }]
}
```

- `preplayParameters`: The `preplayParameters` object should have string-key-string-value combinations, which will be used as query parameters for the Preplay API call. Nested objects are not supported.

- **A Preplay request must include all parameters defined within the playback request, hence these parameters must be included in the THEOplayer source**. This request must also include a digital signature if the 'Require a token for playback' option is enabled in the back-end on the corresponding live channel. Such parameters can be passed in the `playbackURLParameters` argument of the above constructor. 
  
- Uplynk specific documentation on the available playback URL query parameters can be found on the Uplynk documentation site under [Customizing Playback via Parameters](https://docs.uplynk.com/docs/customize-playback-via-parameters)

- Some parameters can be excluded from the digital signature calculation. These parameters may enable certain use cases (e.g. DVR) and would for this reason be excluded from the digital signature.

##### iOS (/tvOS) SDK

```swift
let verizonMediaSource = VerizonMediaSource(
    assetIds: [
        "verizonMedia_content_first", "verizonMedia_ad_break_1", "verizonMedia_content_middle",
        "verizonMedia_ad_break_2", "verizonMedia_content_last"
    ],
    orderedParameters: [("ad","exampleadserver")]
)
```

## Preplay Response

THEOplayer automatically interprets the response returned by the Preplay service. However, if a developer wants to perform their own logic with the Preplay API response, then they can intercept the `preplayresponse` event.

##### iOS (/tvOS) SDK

```swift
let eventListener = self.theoplayer.verizonMedia.addEventListener(type: VerizonMediaEventTypes.VerizonMedia_PREPLAY_RESPONSE) { event in
    // do something with the preplay response
}
```

## Using Tokens

Verizon Media users often leverage URL signatures (i.e. tokens) to further secure their content -- on top of AES-128 encryption or studio DRM.
A token is (typically) generated on back-end using an API key and a set of parameters.
(The documentation at [Basic Setup > Playback URL's > Signing a Playback URL Tutorial](https://docs.vdms.com/video/index.html#Tutorials/Signed-Playback-URL-Tutorial.htm%3FTocPath%3DBasic%2520Setup%7CPlayback%2520URLs%7C_____2) describes this process.) This set of parameters should also be passed along to the `preplayParameters` in a [VerizonMediaSource](pathname:///theoplayer/v8/api-reference/web/interfaces/VerizonMediaSource.html).
If you do not configure the `preplayParameters` (or `orderedParameters`) correctly in relation to your signature parameters, then the Preplay request made by THEOplayer will most likely return an invalid Preplay response, preventing THEOplayer from setting up your stream.

Let's consider a set-up where a Verizon Media customer uses both URL signatures and multi-DRM.
[When you do DRM, you must specify the `rmt` and `manifest` parameter](https://docs.vdms.com/video/index.html#Develop/Preplayv2.htm?Highlight=rmt),
**or** you can set `allowrmt` to `1` instead. We recommend using the latter, as demonstrated in our Node.js reference project at [https://github.com/THEOplayer/theoplayer-verizon-media-node-js](https://github.com/THEOplayer/theoplayer-verizon-media-node-js).

So, let's say you want to generate a signature on your back-end that is compatible with HLS + FairPlay, MPEG-DASH + Widevine and MPEG-DASH + PlayReady,
then it could look like the snippet below using `allowrmt`.

```js
let params = {
  v: '2',
  tc: '1',
  exp: 36000,
  rn: 12345,
  ct: 'a',
  cid: '<CENSORED>',
  allowrmt: 1,
};
let query = Object.keys(params)
  .map((key) => key + '=' + params[key])
  .join('&');
let sig = CryptoJS.HmacSHA256(query, '<API_SECRET>').toString();
params['sig'] = sig;
```

Now you want to communicate this entire `params` object to your client-side, and set it as the value for `preplayParameters`:

```js
player.source = {
  sources: {
    integration: 'verizon-media',
    id: '<CENSORED>',
    preplayParameters: params,
    assetType: 'asset',
    contentProtected: true,
  },
};
```

When there's a mismatch between signature parameters and Preplay parameters, the Preplay response usually returns `Invalid token signature` and playback is not possible.

Having difficulties figuring out tokens, DRM and THEOplayer? Check out the Node.js reference project at [https://github.com/THEOplayer/theoplayer-verizon-media-node-js](https://github.com/THEOplayer/theoplayer-verizon-media-node-js).

# Related articles

- [Verizon Media - Ads](../../../how-to-guides/07-miscellaneous/02-verizon-media/02-ads.md)
- [Verizon Media - Ping](../../../how-to-guides/07-miscellaneous/02-verizon-media/03-ping.md)
