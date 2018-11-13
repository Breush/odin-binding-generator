# 1 "<stdin>"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "<stdin>"
# 332 "<stdin>"
typedef int8_t mal_int8;
typedef uint8_t mal_uint8;
typedef int16_t mal_int16;
typedef uint16_t mal_uint16;
typedef int32_t mal_int32;
typedef uint32_t mal_uint32;
typedef int64_t mal_int64;
typedef uint64_t mal_uint64;
typedef uintptr_t mal_uintptr;

typedef mal_uint8 mal_bool8;
typedef mal_uint32 mal_bool32;



typedef void* mal_handle;
typedef void* mal_ptr;
typedef void (* mal_proc)(void);
# 405 "<stdin>"
typedef struct mal_context mal_context;
typedef struct mal_device mal_device;

typedef mal_uint8 mal_channel;
# 465 "<stdin>"
typedef int mal_result;
# 531 "<stdin>"
typedef enum
{
    mal_stream_format_pcm = 0,
} mal_stream_format;

typedef enum
{
    mal_stream_layout_interleaved = 0,
    mal_stream_layout_deinterleaved
} mal_stream_layout;

typedef enum
{
    mal_dither_mode_none = 0,
    mal_dither_mode_rectangle,
    mal_dither_mode_triangle
} mal_dither_mode;

typedef enum
{


    mal_format_unknown = 0,
    mal_format_u8 = 1,
    mal_format_s16 = 2,
    mal_format_s24 = 3,
    mal_format_s32 = 4,
    mal_format_f32 = 5,
    mal_format_count
} mal_format;

typedef enum
{
    mal_channel_mix_mode_planar_blend = 0,
    mal_channel_mix_mode_simple,
    mal_channel_mix_mode_default = mal_channel_mix_mode_planar_blend
} mal_channel_mix_mode;

typedef enum
{
    mal_standard_channel_map_microsoft,
    mal_standard_channel_map_alsa,
    mal_standard_channel_map_rfc3551,
    mal_standard_channel_map_flac,
    mal_standard_channel_map_vorbis,
    mal_standard_channel_map_sound4,
    mal_standard_channel_map_sndio,
    mal_standard_channel_map_default = mal_standard_channel_map_microsoft
} mal_standard_channel_map;

typedef enum
{
    mal_performance_profile_low_latency = 0,
    mal_performance_profile_conservative
} mal_performance_profile;


typedef struct mal_format_converter mal_format_converter;
typedef mal_uint32 (* mal_format_converter_read_proc) (mal_format_converter* pConverter, mal_uint32 frameCount, void* pFramesOut, void* pUserData);
typedef mal_uint32 (* mal_format_converter_read_deinterleaved_proc)(mal_format_converter* pConverter, mal_uint32 frameCount, void** ppSamplesOut, void* pUserData);

typedef struct
{
    mal_format formatIn;
    mal_format formatOut;
    mal_uint32 channels;
    mal_stream_format streamFormatIn;
    mal_stream_format streamFormatOut;
    mal_dither_mode ditherMode;
    mal_bool32 noSSE2 : 1;
    mal_bool32 noAVX2 : 1;
    mal_bool32 noAVX512 : 1;
    mal_bool32 noNEON : 1;
    mal_format_converter_read_proc onRead;
    mal_format_converter_read_deinterleaved_proc onReadDeinterleaved;
    void* pUserData;
} mal_format_converter_config;

struct mal_format_converter
{
    mal_format_converter_config config;
    mal_bool32 useSSE2 : 1;
    mal_bool32 useAVX2 : 1;
    mal_bool32 useAVX512 : 1;
    mal_bool32 useNEON : 1;
    void (* onConvertPCM)(void* dst, const void* src, mal_uint64 count, mal_dither_mode ditherMode);
    void (* onInterleavePCM)(void* dst, const void** src, mal_uint64 frameCount, mal_uint32 channels);
    void (* onDeinterleavePCM)(void** dst, const void* src, mal_uint64 frameCount, mal_uint32 channels);
};



typedef struct mal_channel_router mal_channel_router;
typedef mal_uint32 (* mal_channel_router_read_deinterleaved_proc)(mal_channel_router* pRouter, mal_uint32 frameCount, void** ppSamplesOut, void* pUserData);

typedef struct
{
    mal_uint32 channelsIn;
    mal_uint32 channelsOut;
    mal_channel channelMapIn[32];
    mal_channel channelMapOut[32];
    mal_channel_mix_mode mixingMode;
    mal_bool32 noSSE2 : 1;
    mal_bool32 noAVX2 : 1;
    mal_bool32 noAVX512 : 1;
    mal_bool32 noNEON : 1;
    mal_channel_router_read_deinterleaved_proc onReadDeinterleaved;
    void* pUserData;
} mal_channel_router_config;

struct mal_channel_router
{
    mal_channel_router_config config;
    mal_bool32 isPassthrough : 1;
    mal_bool32 isSimpleShuffle : 1;
    mal_bool32 useSSE2 : 1;
    mal_bool32 useAVX2 : 1;
    mal_bool32 useAVX512 : 1;
    mal_bool32 useNEON : 1;
    mal_uint8 shuffleTable[32];
    float weights[32][32];
};



typedef struct mal_src mal_src;

typedef mal_uint32 (* mal_src_read_deinterleaved_proc)(mal_src* pSRC, mal_uint32 frameCount, void** ppSamplesOut, void* pUserData);

typedef enum
{
    mal_src_algorithm_sinc = 0,
    mal_src_algorithm_linear,
    mal_src_algorithm_none,
    mal_src_algorithm_default = mal_src_algorithm_sinc
} mal_src_algorithm;

typedef enum
{
    mal_src_sinc_window_function_hann = 0,
    mal_src_sinc_window_function_rectangular,
    mal_src_sinc_window_function_default = mal_src_sinc_window_function_hann
} mal_src_sinc_window_function;

typedef struct
{
    mal_src_sinc_window_function windowFunction;
    mal_uint32 windowWidth;
} mal_src_config_sinc;

typedef struct
{
    mal_uint32 sampleRateIn;
    mal_uint32 sampleRateOut;
    mal_uint32 channels;
    mal_src_algorithm algorithm;
    mal_bool32 neverConsumeEndOfInput : 1;
    mal_bool32 noSSE2 : 1;
    mal_bool32 noAVX2 : 1;
    mal_bool32 noAVX512 : 1;
    mal_bool32 noNEON : 1;
    mal_src_read_deinterleaved_proc onReadDeinterleaved;
    void* pUserData;
    union
    {
        mal_src_config_sinc sinc;
    };
} mal_src_config;

struct __attribute__((aligned(64))) mal_src
{
    union
    {
        struct
        {
            __attribute__((aligned(64))) float input[32][256];
            float timeIn;
            mal_uint32 leftoverFrames;
        } linear;

        struct
        {
            __attribute__((aligned(64))) float input[32][32*2 + 256];
            float timeIn;
            mal_uint32 inputFrameCount;
            mal_uint32 windowPosInSamples;
            float table[32*1 * 8];
        } sinc;
    };

    mal_src_config config;
    mal_bool32 isEndOfInputLoaded : 1;
    mal_bool32 useSSE2 : 1;
    mal_bool32 useAVX2 : 1;
    mal_bool32 useAVX512 : 1;
    mal_bool32 useNEON : 1;
};

typedef struct mal_dsp mal_dsp;
typedef mal_uint32 (* mal_dsp_read_proc)(mal_dsp* pDSP, mal_uint32 frameCount, void* pSamplesOut, void* pUserData);

typedef struct
{
    mal_format formatIn;
    mal_uint32 channelsIn;
    mal_uint32 sampleRateIn;
    mal_channel channelMapIn[32];
    mal_format formatOut;
    mal_uint32 channelsOut;
    mal_uint32 sampleRateOut;
    mal_channel channelMapOut[32];
    mal_channel_mix_mode channelMixMode;
    mal_dither_mode ditherMode;
    mal_src_algorithm srcAlgorithm;
    mal_bool32 allowDynamicSampleRate;
    mal_bool32 neverConsumeEndOfInput : 1;
    mal_bool32 noSSE2 : 1;
    mal_bool32 noAVX2 : 1;
    mal_bool32 noAVX512 : 1;
    mal_bool32 noNEON : 1;
    mal_dsp_read_proc onRead;
    void* pUserData;
    union
    {
        mal_src_config_sinc sinc;
    };
} mal_dsp_config;

struct __attribute__((aligned(64))) mal_dsp
{
    mal_dsp_read_proc onRead;
    void* pUserData;
    mal_format_converter formatConverterIn;
    mal_format_converter formatConverterOut;
    mal_channel_router channelRouter;
    mal_src src;
    mal_bool32 isDynamicSampleRateAllowed : 1;
    mal_bool32 isPreFormatConversionRequired : 1;
    mal_bool32 isPostFormatConversionRequired : 1;
    mal_bool32 isChannelRoutingRequired : 1;
    mal_bool32 isSRCRequired : 1;
    mal_bool32 isChannelRoutingAtStart : 1;
    mal_bool32 isPassthrough : 1;
};
# 795 "<stdin>"
void mal_get_standard_channel_map(mal_standard_channel_map standardChannelMap, mal_uint32 channels, mal_channel channelMap[32]);


void mal_channel_map_copy(mal_channel* pOut, const mal_channel* pIn, mal_uint32 channels);
# 809 "<stdin>"
mal_bool32 mal_channel_map_valid(mal_uint32 channels, const mal_channel channelMap[32]);




mal_bool32 mal_channel_map_equal(mal_uint32 channels, const mal_channel channelMapA[32], const mal_channel channelMapB[32]);


mal_bool32 mal_channel_map_blank(mal_uint32 channels, const mal_channel channelMap[32]);


mal_bool32 mal_channel_map_contains_channel_position(mal_uint32 channels, const mal_channel channelMap[32], mal_channel channelPosition);
# 863 "<stdin>"
mal_result mal_format_converter_init(const mal_format_converter_config* pConfig, mal_format_converter* pConverter);


mal_uint64 mal_format_converter_read(mal_format_converter* pConverter, mal_uint64 frameCount, void* pFramesOut, void* pUserData);


mal_uint64 mal_format_converter_read_deinterleaved(mal_format_converter* pConverter, mal_uint64 frameCount, void** ppSamplesOut, void* pUserData);



mal_format_converter_config mal_format_converter_config_init_new(void);
mal_format_converter_config mal_format_converter_config_init(mal_format formatIn, mal_format formatOut, mal_uint32 channels, mal_format_converter_read_proc onRead, void* pUserData);
mal_format_converter_config mal_format_converter_config_init_deinterleaved(mal_format formatIn, mal_format formatOut, mal_uint32 channels, mal_format_converter_read_deinterleaved_proc onReadDeinterleaved, void* pUserData);
# 944 "<stdin>"
mal_result mal_channel_router_init(const mal_channel_router_config* pConfig, mal_channel_router* pRouter);


mal_uint64 mal_channel_router_read_deinterleaved(mal_channel_router* pRouter, mal_uint64 frameCount, void** ppSamplesOut, void* pUserData);


mal_channel_router_config mal_channel_router_config_init(mal_uint32 channelsIn, const mal_channel channelMapIn[32], mal_uint32 channelsOut, const mal_channel channelMapOut[32], mal_channel_mix_mode mixingMode, mal_channel_router_read_deinterleaved_proc onRead, void* pUserData);
# 961 "<stdin>"
mal_result mal_src_init(const mal_src_config* pConfig, mal_src* pSRC);




mal_result mal_src_set_input_sample_rate(mal_src* pSRC, mal_uint32 sampleRateIn);







mal_result mal_src_set_output_sample_rate(mal_src* pSRC, mal_uint32 sampleRateOut);





mal_result mal_src_set_sample_rate(mal_src* pSRC, mal_uint32 sampleRateIn, mal_uint32 sampleRateOut);




mal_uint64 mal_src_read_deinterleaved(mal_src* pSRC, mal_uint64 frameCount, void** ppSamplesOut, void* pUserData);



mal_src_config mal_src_config_init_new(void);
mal_src_config mal_src_config_init(mal_uint32 sampleRateIn, mal_uint32 sampleRateOut, mal_uint32 channels, mal_src_read_deinterleaved_proc onReadDeinterleaved, void* pUserData);
# 1000 "<stdin>"
mal_result mal_dsp_init(const mal_dsp_config* pConfig, mal_dsp* pDSP);






mal_result mal_dsp_set_input_sample_rate(mal_dsp* pDSP, mal_uint32 sampleRateOut);
# 1017 "<stdin>"
mal_result mal_dsp_set_output_sample_rate(mal_dsp* pDSP, mal_uint32 sampleRateOut);







mal_result mal_dsp_set_sample_rate(mal_dsp* pDSP, mal_uint32 sampleRateIn, mal_uint32 sampleRateOut);



mal_uint64 mal_dsp_read(mal_dsp* pDSP, mal_uint64 frameCount, void* pFramesOut, void* pUserData);


mal_dsp_config mal_dsp_config_init_new(void);
mal_dsp_config mal_dsp_config_init(mal_format formatIn, mal_uint32 channelsIn, mal_uint32 sampleRateIn, mal_format formatOut, mal_uint32 channelsOut, mal_uint32 sampleRateOut, mal_dsp_read_proc onRead, void* pUserData);
mal_dsp_config mal_dsp_config_init_ex(mal_format formatIn, mal_uint32 channelsIn, mal_uint32 sampleRateIn, mal_channel channelMapIn[32], mal_format formatOut, mal_uint32 channelsOut, mal_uint32 sampleRateOut, mal_channel channelMapOut[32], mal_dsp_read_proc onRead, void* pUserData);
# 1043 "<stdin>"
mal_uint64 mal_convert_frames(void* pOut, mal_format formatOut, mal_uint32 channelsOut, mal_uint32 sampleRateOut, const void* pIn, mal_format formatIn, mal_uint32 channelsIn, mal_uint32 sampleRateIn, mal_uint64 frameCountIn);
mal_uint64 mal_convert_frames_ex(void* pOut, mal_format formatOut, mal_uint32 channelsOut, mal_uint32 sampleRateOut, mal_channel channelMapOut[32], const void* pIn, mal_format formatIn, mal_uint32 channelsIn, mal_uint32 sampleRateIn, mal_channel channelMapIn[32], mal_uint64 frameCountIn);
# 1055 "<stdin>"
void* mal_malloc(size_t sz);


void* mal_realloc(void* p, size_t sz);


void mal_free(void* p);


void* mal_aligned_malloc(size_t sz, size_t alignment);


void mal_aligned_free(void* p);


const char* mal_get_format_name(mal_format format);


void mal_blend_f32(float* pOut, float* pInA, float* pInB, float factor, mal_uint32 channels);







mal_uint32 mal_get_bytes_per_sample(mal_format format);
static inline __attribute__((always_inline)) mal_uint32 mal_get_bytes_per_frame(mal_format format, mal_uint32 channels) { return mal_get_bytes_per_sample(format) * channels; }







void mal_pcm_u8_to_s16(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_u8_to_s24(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_u8_to_s32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_u8_to_f32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s16_to_u8(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s16_to_s24(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s16_to_s32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s16_to_f32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s24_to_u8(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s24_to_s16(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s24_to_s32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s24_to_f32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s32_to_u8(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s32_to_s16(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s32_to_s24(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_s32_to_f32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_f32_to_u8(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_f32_to_s16(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_f32_to_s24(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_f32_to_s32(void* pOut, const void* pIn, mal_uint64 count, mal_dither_mode ditherMode);
void mal_pcm_convert(void* pOut, mal_format formatOut, const void* pIn, mal_format formatIn, mal_uint64 sampleCount, mal_dither_mode ditherMode);
# 1224 "<stdin>"
typedef enum
{
    mal_backend_null,
    mal_backend_wasapi,
    mal_backend_dsound,
    mal_backend_winmm,
    mal_backend_alsa,
    mal_backend_pulseaudio,
    mal_backend_jack,
    mal_backend_coreaudio,
    mal_backend_sndio,
    mal_backend_audio4,
    mal_backend_oss,
    mal_backend_opensl,
    mal_backend_openal,
    mal_backend_sdl
} mal_backend;


typedef enum
{
    mal_thread_priority_idle = -5,
    mal_thread_priority_lowest = -4,
    mal_thread_priority_low = -3,
    mal_thread_priority_normal = -2,
    mal_thread_priority_high = -1,
    mal_thread_priority_highest = 0,
    mal_thread_priority_realtime = 1,
    mal_thread_priority_default = 0
} mal_thread_priority;

typedef struct
{
    mal_context* pContext;

    union
    {







        struct
        {
            pthread_t thread;
        } posix;


        int _unused;
    };
} mal_thread;

typedef struct
{
    mal_context* pContext;

    union
    {







        struct
        {
            pthread_mutex_t mutex;
        } posix;


        int _unused;
    };
} mal_mutex;

typedef struct
{
    mal_context* pContext;

    union
    {







        struct
        {
            pthread_mutex_t mutex;
            pthread_cond_t condition;
            mal_uint32 value;
        } posix;


        int _unused;
    };
} mal_event;





typedef void (* mal_log_proc) (mal_context* pContext, mal_device* pDevice, const char* message);
typedef void (* mal_recv_proc)(mal_device* pDevice, mal_uint32 frameCount, const void* pSamples);
typedef mal_uint32 (* mal_send_proc)(mal_device* pDevice, mal_uint32 frameCount, void* pSamples);
typedef void (* mal_stop_proc)(mal_device* pDevice);

typedef enum
{
    mal_device_type_playback,
    mal_device_type_capture
} mal_device_type;

typedef enum
{
    mal_share_mode_shared = 0,
    mal_share_mode_exclusive,
} mal_share_mode;

typedef union
{
# 1359 "<stdin>"
    char alsa[256];


    char pulse[256];


    int jack;
# 1383 "<stdin>"
    char openal[256];


    int sdl;


    int nullbackend;

} mal_device_id;

typedef struct
{

    mal_device_id id;
    char name[256];







    mal_uint32 formatCount;
    mal_format formats[mal_format_count];
    mal_uint32 minChannels;
    mal_uint32 maxChannels;
    mal_uint32 minSampleRate;
    mal_uint32 maxSampleRate;
} mal_device_info;

typedef struct
{
    mal_int64 counter;
} mal_timer;

typedef struct
{
    mal_format format;
    mal_uint32 channels;
    mal_uint32 sampleRate;
    mal_channel channelMap[32];
    mal_uint32 bufferSizeInFrames;
    mal_uint32 bufferSizeInMilliseconds;
    mal_uint32 periods;
    mal_share_mode shareMode;
    mal_performance_profile performanceProfile;
    mal_recv_proc onRecvCallback;
    mal_send_proc onSendCallback;
    mal_stop_proc onStopCallback;

    struct
    {
        mal_bool32 noMMap;
    } alsa;

    struct
    {
        const char* pStreamName;
    } pulse;
} mal_device_config;

typedef struct
{
    mal_log_proc onLog;
    mal_thread_priority threadPriority;

    struct
    {
        mal_bool32 useVerboseDeviceEnumeration;
    } alsa;

    struct
    {
        const char* pApplicationName;
        const char* pServerName;
        mal_bool32 tryAutoSpawn;
    } pulse;

    struct
    {
        const char* pClientName;
        mal_bool32 tryStartServer;
    } jack;
} mal_context_config;

typedef mal_bool32 (* mal_enum_devices_callback_proc)(mal_context* pContext, mal_device_type type, const mal_device_info* pInfo, void* pUserData);

struct mal_context
{
    mal_backend backend;
    mal_context_config config;
    mal_mutex deviceEnumLock;
    mal_mutex deviceInfoLock;
    mal_uint32 deviceInfoCapacity;
    mal_uint32 playbackDeviceInfoCount;
    mal_uint32 captureDeviceInfoCount;
    mal_device_info* pDeviceInfos;
    mal_bool32 isBackendAsynchronous : 1;

    mal_result (* onUninit )(mal_context* pContext);
    mal_bool32 (* onDeviceIDEqual )(mal_context* pContext, const mal_device_id* pID0, const mal_device_id* pID1);
    mal_result (* onEnumDevices )(mal_context* pContext, mal_enum_devices_callback_proc callback, void* pUserData);
    mal_result (* onGetDeviceInfo )(mal_context* pContext, mal_device_type type, const mal_device_id* pDeviceID, mal_share_mode shareMode, mal_device_info* pDeviceInfo);
    mal_result (* onDeviceInit )(mal_context* pContext, mal_device_type type, const mal_device_id* pDeviceID, const mal_device_config* pConfig, mal_device* pDevice);
    void (* onDeviceUninit )(mal_device* pDevice);
    mal_result (* onDeviceReinit )(mal_device* pDevice);
    mal_result (* onDeviceStart )(mal_device* pDevice);
    mal_result (* onDeviceStop )(mal_device* pDevice);
    mal_result (* onDeviceBreakMainLoop)(mal_device* pDevice);
    mal_result (* onDeviceMainLoop )(mal_device* pDevice);

    union
    {
# 1536 "<stdin>"
        struct
        {
            mal_handle asoundSO;
            mal_proc snd_pcm_open;
            mal_proc snd_pcm_close;
            mal_proc snd_pcm_hw_params_sizeof;
            mal_proc snd_pcm_hw_params_any;
            mal_proc snd_pcm_hw_params_set_format;
            mal_proc snd_pcm_hw_params_set_format_first;
            mal_proc snd_pcm_hw_params_get_format_mask;
            mal_proc snd_pcm_hw_params_set_channels_near;
            mal_proc snd_pcm_hw_params_set_rate_resample;
            mal_proc snd_pcm_hw_params_set_rate_near;
            mal_proc snd_pcm_hw_params_set_buffer_size_near;
            mal_proc snd_pcm_hw_params_set_periods_near;
            mal_proc snd_pcm_hw_params_set_access;
            mal_proc snd_pcm_hw_params_get_format;
            mal_proc snd_pcm_hw_params_get_channels;
            mal_proc snd_pcm_hw_params_get_channels_min;
            mal_proc snd_pcm_hw_params_get_channels_max;
            mal_proc snd_pcm_hw_params_get_rate;
            mal_proc snd_pcm_hw_params_get_rate_min;
            mal_proc snd_pcm_hw_params_get_rate_max;
            mal_proc snd_pcm_hw_params_get_buffer_size;
            mal_proc snd_pcm_hw_params_get_periods;
            mal_proc snd_pcm_hw_params_get_access;
            mal_proc snd_pcm_hw_params;
            mal_proc snd_pcm_sw_params_sizeof;
            mal_proc snd_pcm_sw_params_current;
            mal_proc snd_pcm_sw_params_set_avail_min;
            mal_proc snd_pcm_sw_params_set_start_threshold;
            mal_proc snd_pcm_sw_params;
            mal_proc snd_pcm_format_mask_sizeof;
            mal_proc snd_pcm_format_mask_test;
            mal_proc snd_pcm_get_chmap;
            mal_proc snd_pcm_prepare;
            mal_proc snd_pcm_start;
            mal_proc snd_pcm_drop;
            mal_proc snd_device_name_hint;
            mal_proc snd_device_name_get_hint;
            mal_proc snd_card_get_index;
            mal_proc snd_device_name_free_hint;
            mal_proc snd_pcm_mmap_begin;
            mal_proc snd_pcm_mmap_commit;
            mal_proc snd_pcm_recover;
            mal_proc snd_pcm_readi;
            mal_proc snd_pcm_writei;
            mal_proc snd_pcm_avail;
            mal_proc snd_pcm_avail_update;
            mal_proc snd_pcm_wait;
            mal_proc snd_pcm_info;
            mal_proc snd_pcm_info_sizeof;
            mal_proc snd_pcm_info_get_name;
            mal_proc snd_config_update_free_global;

            mal_mutex internalDeviceEnumLock;
        } alsa;


        struct
        {
            mal_handle pulseSO;
            mal_proc pa_mainloop_new;
            mal_proc pa_mainloop_free;
            mal_proc pa_mainloop_get_api;
            mal_proc pa_mainloop_iterate;
            mal_proc pa_mainloop_wakeup;
            mal_proc pa_context_new;
            mal_proc pa_context_unref;
            mal_proc pa_context_connect;
            mal_proc pa_context_disconnect;
            mal_proc pa_context_set_state_callback;
            mal_proc pa_context_get_state;
            mal_proc pa_context_get_sink_info_list;
            mal_proc pa_context_get_source_info_list;
            mal_proc pa_context_get_sink_info_by_name;
            mal_proc pa_context_get_source_info_by_name;
            mal_proc pa_operation_unref;
            mal_proc pa_operation_get_state;
            mal_proc pa_channel_map_init_extend;
            mal_proc pa_channel_map_valid;
            mal_proc pa_channel_map_compatible;
            mal_proc pa_stream_new;
            mal_proc pa_stream_unref;
            mal_proc pa_stream_connect_playback;
            mal_proc pa_stream_connect_record;
            mal_proc pa_stream_disconnect;
            mal_proc pa_stream_get_state;
            mal_proc pa_stream_get_sample_spec;
            mal_proc pa_stream_get_channel_map;
            mal_proc pa_stream_get_buffer_attr;
            mal_proc pa_stream_get_device_name;
            mal_proc pa_stream_set_write_callback;
            mal_proc pa_stream_set_read_callback;
            mal_proc pa_stream_flush;
            mal_proc pa_stream_drain;
            mal_proc pa_stream_cork;
            mal_proc pa_stream_trigger;
            mal_proc pa_stream_begin_write;
            mal_proc pa_stream_write;
            mal_proc pa_stream_peek;
            mal_proc pa_stream_drop;
        } pulse;


        struct
        {
            mal_handle jackSO;
            mal_proc jack_client_open;
            mal_proc jack_client_close;
            mal_proc jack_client_name_size;
            mal_proc jack_set_process_callback;
            mal_proc jack_set_buffer_size_callback;
            mal_proc jack_on_shutdown;
            mal_proc jack_get_sample_rate;
            mal_proc jack_get_buffer_size;
            mal_proc jack_get_ports;
            mal_proc jack_activate;
            mal_proc jack_deactivate;
            mal_proc jack_connect;
            mal_proc jack_port_register;
            mal_proc jack_port_name;
            mal_proc jack_port_get_buffer;
            mal_proc jack_free;
        } jack;
# 1730 "<stdin>"
        struct
        {
                        mal_handle hOpenAL;
            mal_proc alcCreateContext;
            mal_proc alcMakeContextCurrent;
            mal_proc alcProcessContext;
            mal_proc alcSuspendContext;
            mal_proc alcDestroyContext;
            mal_proc alcGetCurrentContext;
            mal_proc alcGetContextsDevice;
            mal_proc alcOpenDevice;
            mal_proc alcCloseDevice;
            mal_proc alcGetError;
            mal_proc alcIsExtensionPresent;
            mal_proc alcGetProcAddress;
            mal_proc alcGetEnumValue;
            mal_proc alcGetString;
            mal_proc alcGetIntegerv;
            mal_proc alcCaptureOpenDevice;
            mal_proc alcCaptureCloseDevice;
            mal_proc alcCaptureStart;
            mal_proc alcCaptureStop;
            mal_proc alcCaptureSamples;
            mal_proc alEnable;
            mal_proc alDisable;
            mal_proc alIsEnabled;
            mal_proc alGetString;
            mal_proc alGetBooleanv;
            mal_proc alGetIntegerv;
            mal_proc alGetFloatv;
            mal_proc alGetDoublev;
            mal_proc alGetBoolean;
            mal_proc alGetInteger;
            mal_proc alGetFloat;
            mal_proc alGetDouble;
            mal_proc alGetError;
            mal_proc alIsExtensionPresent;
            mal_proc alGetProcAddress;
            mal_proc alGetEnumValue;
            mal_proc alGenSources;
            mal_proc alDeleteSources;
            mal_proc alIsSource;
            mal_proc alSourcef;
            mal_proc alSource3f;
            mal_proc alSourcefv;
            mal_proc alSourcei;
            mal_proc alSource3i;
            mal_proc alSourceiv;
            mal_proc alGetSourcef;
            mal_proc alGetSource3f;
            mal_proc alGetSourcefv;
            mal_proc alGetSourcei;
            mal_proc alGetSource3i;
            mal_proc alGetSourceiv;
            mal_proc alSourcePlayv;
            mal_proc alSourceStopv;
            mal_proc alSourceRewindv;
            mal_proc alSourcePausev;
            mal_proc alSourcePlay;
            mal_proc alSourceStop;
            mal_proc alSourceRewind;
            mal_proc alSourcePause;
            mal_proc alSourceQueueBuffers;
            mal_proc alSourceUnqueueBuffers;
            mal_proc alGenBuffers;
            mal_proc alDeleteBuffers;
            mal_proc alIsBuffer;
            mal_proc alBufferData;
            mal_proc alBufferf;
            mal_proc alBuffer3f;
            mal_proc alBufferfv;
            mal_proc alBufferi;
            mal_proc alBuffer3i;
            mal_proc alBufferiv;
            mal_proc alGetBufferf;
            mal_proc alGetBuffer3f;
            mal_proc alGetBufferfv;
            mal_proc alGetBufferi;
            mal_proc alGetBuffer3i;
            mal_proc alGetBufferiv;

            mal_bool32 isEnumerationSupported : 1;
            mal_bool32 isFloat32Supported : 1;
            mal_bool32 isMCFormatsSupported : 1;
        } openal;


        struct
        {
            mal_handle hSDL;
            mal_proc SDL_InitSubSystem;
            mal_proc SDL_QuitSubSystem;
            mal_proc SDL_CloseAudio;
            mal_proc SDL_OpenAudio;
            mal_proc SDL_PauseAudio;
            mal_proc SDL_GetNumAudioDevices;
            mal_proc SDL_GetAudioDeviceName;
            mal_proc SDL_CloseAudioDevice;
            mal_proc SDL_OpenAudioDevice;
            mal_proc SDL_PauseAudioDevice;

            mal_bool32 usingSDL1;
        } sdl;


        struct
        {
            int _unused;
        } null_backend;

    };

    union
    {
# 1866 "<stdin>"
        struct
        {
            mal_handle pthreadSO;
            mal_proc pthread_create;
            mal_proc pthread_join;
            mal_proc pthread_mutex_init;
            mal_proc pthread_mutex_destroy;
            mal_proc pthread_mutex_lock;
            mal_proc pthread_mutex_unlock;
            mal_proc pthread_cond_init;
            mal_proc pthread_cond_destroy;
            mal_proc pthread_cond_wait;
            mal_proc pthread_cond_signal;
            mal_proc pthread_attr_init;
            mal_proc pthread_attr_destroy;
            mal_proc pthread_attr_setschedpolicy;
            mal_proc pthread_attr_getschedparam;
            mal_proc pthread_attr_setschedparam;
        } posix;

        int _unused;
    };
};

struct __attribute__((aligned(64))) mal_device
{
    mal_context* pContext;
    mal_device_type type;
    mal_format format;
    mal_uint32 channels;
    mal_uint32 sampleRate;
    mal_channel channelMap[32];
    mal_uint32 bufferSizeInFrames;
    mal_uint32 bufferSizeInMilliseconds;
    mal_uint32 periods;
    mal_uint32 state;
    mal_recv_proc onRecv;
    mal_send_proc onSend;
    mal_stop_proc onStop;
    void* pUserData;
    char name[256];
    mal_device_config initConfig;
    mal_mutex lock;
    mal_event wakeupEvent;
    mal_event startEvent;
    mal_event stopEvent;
    mal_thread thread;
    mal_result workResult;
    mal_bool32 usingDefaultFormat : 1;
    mal_bool32 usingDefaultChannels : 1;
    mal_bool32 usingDefaultSampleRate : 1;
    mal_bool32 usingDefaultChannelMap : 1;
    mal_bool32 usingDefaultBufferSize : 1;
    mal_bool32 usingDefaultPeriods : 1;
    mal_bool32 exclusiveMode : 1;
    mal_bool32 isOwnerOfContext : 1;
    mal_bool32 isDefaultDevice : 1;
    mal_format internalFormat;
    mal_uint32 internalChannels;
    mal_uint32 internalSampleRate;
    mal_channel internalChannelMap[32];
    mal_dsp dsp;
    mal_uint32 _dspFrameCount;
    const mal_uint8* _dspFrames;

    union
    {
# 1977 "<stdin>"
        struct
        {
                           mal_ptr pPCM;
            mal_bool32 isUsingMMap : 1;
            mal_bool32 breakFromMainLoop : 1;
            void* pIntermediaryBuffer;
        } alsa;


        struct
        {
                             mal_ptr pMainLoop;
                                 mal_ptr pAPI;
                            mal_ptr pPulseContext;
                           mal_ptr pStream;
                                 mal_uint32 pulseContextState;
            mal_uint32 fragmentSizeInBytes;
            mal_bool32 breakFromMainLoop : 1;
        } pulse;


        struct
        {
                               mal_ptr pClient;
                             mal_ptr pPorts[32];
            float* pIntermediaryBuffer;
        } jack;
# 2058 "<stdin>"
        struct
        {
                            mal_ptr pContextALC;
                           mal_ptr pDeviceALC;
                       mal_uint32 sourceAL;
                       mal_uint32 buffersAL[4];
                       mal_uint32 formatAL;
            mal_uint32 subBufferSizeInFrames;
            mal_uint8* pIntermediaryBuffer;
            mal_uint32 iNextBuffer;
            mal_bool32 breakFromMainLoop;
        } openal;


        struct
        {
            mal_uint32 deviceID;
        } sdl;


        struct
        {
            mal_timer timer;
            mal_uint32 lastProcessedFrame;
            mal_bool32 breakFromMainLoop;
            mal_uint8* pBuffer;
        } null_device;

    };
};
# 2127 "<stdin>"
mal_result mal_context_init(const mal_backend backends[], mal_uint32 backendCount, const mal_context_config* pConfig, mal_context* pContext);
# 2137 "<stdin>"
mal_result mal_context_uninit(mal_context* pContext);
# 2167 "<stdin>"
mal_result mal_context_enumerate_devices(mal_context* pContext, mal_enum_devices_callback_proc callback, void* pUserData);
# 2188 "<stdin>"
mal_result mal_context_get_devices(mal_context* pContext, mal_device_info** ppPlaybackDeviceInfos, mal_uint32* pPlaybackDeviceCount, mal_device_info** ppCaptureDeviceInfos, mal_uint32* pCaptureDeviceCount);
# 2208 "<stdin>"
mal_result mal_context_get_device_info(mal_context* pContext, mal_device_type type, const mal_device_id* pDeviceID, mal_share_mode shareMode, mal_device_info* pDeviceInfo);
# 2261 "<stdin>"
mal_result mal_device_init(mal_context* pContext, mal_device_type type, mal_device_id* pDeviceID, const mal_device_config* pConfig, void* pUserData, mal_device* pDevice);





mal_result mal_device_init_ex(const mal_backend backends[], mal_uint32 backendCount, const mal_context_config* pContextConfig, mal_device_type type, mal_device_id* pDeviceID, const mal_device_config* pConfig, void* pUserData, mal_device* pDevice);
# 2280 "<stdin>"
void mal_device_uninit(mal_device* pDevice);







void mal_device_set_recv_callback(mal_device* pDevice, mal_recv_proc proc);
# 2300 "<stdin>"
void mal_device_set_send_callback(mal_device* pDevice, mal_send_proc proc);





void mal_device_set_stop_callback(mal_device* pDevice, mal_stop_proc proc);
# 2341 "<stdin>"
mal_result mal_device_start(mal_device* pDevice);
# 2369 "<stdin>"
mal_result mal_device_stop(mal_device* pDevice);
# 2381 "<stdin>"
mal_bool32 mal_device_is_started(mal_device* pDevice);







mal_uint32 mal_device_get_buffer_size_in_bytes(mal_device* pDevice);



mal_context_config mal_context_config_init(mal_log_proc onLog);
# 2404 "<stdin>"
mal_device_config mal_device_config_init_default(void);
mal_device_config mal_device_config_init_default_capture(mal_recv_proc onRecvCallback);
mal_device_config mal_device_config_init_default_playback(mal_send_proc onSendCallback);
# 2471 "<stdin>"
mal_device_config mal_device_config_init_ex(mal_format format, mal_uint32 channels, mal_uint32 sampleRate, mal_channel channelMap[32], mal_recv_proc onRecvCallback, mal_send_proc onSendCallback);


static inline __attribute__((always_inline)) mal_device_config mal_device_config_init(mal_format format, mal_uint32 channels, mal_uint32 sampleRate, mal_recv_proc onRecvCallback, mal_send_proc onSendCallback) { return mal_device_config_init_ex(format, channels, sampleRate, 0, onRecvCallback, onSendCallback); }


static inline __attribute__((always_inline)) mal_device_config mal_device_config_init_capture_ex(mal_format format, mal_uint32 channels, mal_uint32 sampleRate, mal_channel channelMap[32], mal_recv_proc onRecvCallback) { return mal_device_config_init_ex(format, channels, sampleRate, channelMap, onRecvCallback, 0); }
static inline __attribute__((always_inline)) mal_device_config mal_device_config_init_capture(mal_format format, mal_uint32 channels, mal_uint32 sampleRate, mal_recv_proc onRecvCallback) { return mal_device_config_init_capture_ex(format, channels, sampleRate, 0, onRecvCallback); }


static inline __attribute__((always_inline)) mal_device_config mal_device_config_init_playback_ex(mal_format format, mal_uint32 channels, mal_uint32 sampleRate, mal_channel channelMap[32], mal_send_proc onSendCallback) { return mal_device_config_init_ex(format, channels, sampleRate, channelMap, 0, onSendCallback); }
static inline __attribute__((always_inline)) mal_device_config mal_device_config_init_playback(mal_format format, mal_uint32 channels, mal_uint32 sampleRate, mal_send_proc onSendCallback) { return mal_device_config_init_playback_ex(format, channels, sampleRate, 0, onSendCallback); }
# 2495 "<stdin>"
mal_result mal_mutex_init(mal_context* pContext, mal_mutex* pMutex);


void mal_mutex_uninit(mal_mutex* pMutex);


void mal_mutex_lock(mal_mutex* pMutex);


void mal_mutex_unlock(mal_mutex* pMutex);



const char* mal_get_backend_name(mal_backend backend);




mal_uint32 mal_scale_buffer_size(mal_uint32 baseBufferSize, float scale);


mal_uint32 mal_calculate_buffer_size_in_milliseconds_from_frames(mal_uint32 bufferSizeInFrames, mal_uint32 sampleRate);


mal_uint32 mal_calculate_buffer_size_in_frames_from_milliseconds(mal_uint32 bufferSizeInMilliseconds, mal_uint32 sampleRate);


mal_uint32 mal_get_default_buffer_size_in_milliseconds(mal_performance_profile performanceProfile);


mal_uint32 mal_get_default_buffer_size_in_frames(mal_performance_profile performanceProfile, mal_uint32 sampleRate);
# 2539 "<stdin>"
typedef struct mal_decoder mal_decoder;

typedef enum
{
    mal_seek_origin_start,
    mal_seek_origin_current
} mal_seek_origin;

typedef size_t (* mal_decoder_read_proc) (mal_decoder* pDecoder, void* pBufferOut, size_t bytesToRead);
typedef mal_bool32 (* mal_decoder_seek_proc) (mal_decoder* pDecoder, int byteOffset, mal_seek_origin origin);
typedef mal_result (* mal_decoder_seek_to_frame_proc)(mal_decoder* pDecoder, mal_uint64 frameIndex);
typedef mal_result (* mal_decoder_uninit_proc) (mal_decoder* pDecoder);

typedef struct
{
    mal_format format;
    mal_uint32 channels;
    mal_uint32 sampleRate;
    mal_channel channelMap[32];
    mal_channel_mix_mode channelMixMode;
    mal_dither_mode ditherMode;
    mal_src_algorithm srcAlgorithm;
    union
    {
        mal_src_config_sinc sinc;
    } src;
} mal_decoder_config;

struct mal_decoder
{
    mal_decoder_read_proc onRead;
    mal_decoder_seek_proc onSeek;
    void* pUserData;
    mal_format internalFormat;
    mal_uint32 internalChannels;
    mal_uint32 internalSampleRate;
    mal_channel internalChannelMap[32];
    mal_format outputFormat;
    mal_uint32 outputChannels;
    mal_uint32 outputSampleRate;
    mal_channel outputChannelMap[32];
    mal_dsp dsp;
    mal_decoder_seek_to_frame_proc onSeekToFrame;
    mal_decoder_uninit_proc onUninit;
    void* pInternalDecoder;
    struct
    {
        const mal_uint8* pData;
        size_t dataSize;
        size_t currentReadPos;
    } memory;
};

mal_decoder_config mal_decoder_config_init(mal_format outputFormat, mal_uint32 outputChannels, mal_uint32 outputSampleRate);

mal_result mal_decoder_init(mal_decoder_read_proc onRead, mal_decoder_seek_proc onSeek, void* pUserData, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_wav(mal_decoder_read_proc onRead, mal_decoder_seek_proc onSeek, void* pUserData, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_flac(mal_decoder_read_proc onRead, mal_decoder_seek_proc onSeek, void* pUserData, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_vorbis(mal_decoder_read_proc onRead, mal_decoder_seek_proc onSeek, void* pUserData, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_mp3(mal_decoder_read_proc onRead, mal_decoder_seek_proc onSeek, void* pUserData, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_raw(mal_decoder_read_proc onRead, mal_decoder_seek_proc onSeek, void* pUserData, const mal_decoder_config* pConfigIn, const mal_decoder_config* pConfigOut, mal_decoder* pDecoder);

mal_result mal_decoder_init_memory(const void* pData, size_t dataSize, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_memory_wav(const void* pData, size_t dataSize, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_memory_flac(const void* pData, size_t dataSize, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_memory_vorbis(const void* pData, size_t dataSize, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_memory_mp3(const void* pData, size_t dataSize, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_memory_raw(const void* pData, size_t dataSize, const mal_decoder_config* pConfigIn, const mal_decoder_config* pConfigOut, mal_decoder* pDecoder);


mal_result mal_decoder_init_file(const char* pFilePath, const mal_decoder_config* pConfig, mal_decoder* pDecoder);
mal_result mal_decoder_init_file_wav(const char* pFilePath, const mal_decoder_config* pConfig, mal_decoder* pDecoder);


mal_result mal_decoder_uninit(mal_decoder* pDecoder);

mal_uint64 mal_decoder_read(mal_decoder* pDecoder, mal_uint64 frameCount, void* pFramesOut);
mal_result mal_decoder_seek_to_frame(mal_decoder* pDecoder, mal_uint64 frameIndex);





mal_result mal_decode_file(const char* pFilePath, mal_decoder_config* pConfig, mal_uint64* pFrameCountOut, void** ppDataOut);

mal_result mal_decode_memory(const void* pData, size_t dataSize, mal_decoder_config* pConfig, mal_uint64* pFrameCountOut, void** ppDataOut);
# 2635 "<stdin>"
typedef struct
{
    double amplitude;
    double periodsPerSecond;
    double delta;
    double time;
} mal_sine_wave;

mal_result mal_sine_wave_init(double amplitude, double period, mal_uint32 sampleRate, mal_sine_wave* pSineWave);
mal_uint64 mal_sine_wave_read(mal_sine_wave* pSineWave, mal_uint64 count, float* pSamples);
mal_uint64 mal_sine_wave_read_ex(mal_sine_wave* pSineWave, mal_uint64 frameCount, mal_uint32 channels, mal_stream_layout layout, float** ppFrames);
