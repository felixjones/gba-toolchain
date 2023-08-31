#===============================================================================
#
# Locates/Downloads/Installs the FreeImage library
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)

find_package(FreeImage CONFIG QUIET)
if(NOT FreeImage_FOUND)
    set(FREEIMAGE_CHECK_DIRS
        "${TOOLCHAIN_LIBRARY_PATH}/FreeImage"
        /usr
        /usr/local
        /opt
        /opt/local
    )

    find_path(FREEIMAGE_INCLUDE FreeImage.h PATHS ${FREEIMAGE_CHECK_DIRS} PATH_SUFFIXES include)
    find_library(FREEIMAGE_LIBRARY freeimage PATHS ${FREEIMAGE_CHECK_DIRS} PATH_SUFFIXES lib)

    if(FREEIMAGE_INCLUDE AND FREEIMAGE_LIBRARY)
        add_library(freeimage::FreeImage STATIC IMPORTED)
        set_target_properties(freeimage::FreeImage PROPERTIES IMPORTED_LOCATION ${FREEIMAGE_LIBRARY})
        target_include_directories(freeimage::FreeImage INTERFACE ${FREEIMAGE_INCLUDE})
        target_compile_definitions(freeimage::FreeImage INTERFACE FREEIMAGE_LIB OPJ_STATIC DISABLE_PERF_MEASUREMENT)
    endif()
endif()

if(NOT TARGET freeimage::FreeImage)
    set(SOURCE_DIR "${TOOLCHAIN_LIBRARY_PATH}/FreeImage")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(FreeImage C CXX)

        add_library(freeimage STATIC
            Source/FreeImage/BitmapAccess.cpp
            Source/FreeImage/ColorLookup.cpp
            Source/FreeImage/ConversionRGBA16.cpp
            Source/FreeImage/ConversionRGBAF.cpp
            Source/FreeImage/FreeImage.cpp
            Source/FreeImage/FreeImageC.c
            Source/FreeImage/FreeImageIO.cpp
            Source/FreeImage/GetType.cpp
            Source/FreeImage/LFPQuantizer.cpp
            Source/FreeImage/MemoryIO.cpp
            Source/FreeImage/PixelAccess.cpp
            Source/FreeImage/J2KHelper.cpp
            Source/FreeImage/MNGHelper.cpp
            Source/FreeImage/Plugin.cpp
            Source/FreeImage/PluginBMP.cpp
            Source/FreeImage/PluginCUT.cpp
            Source/FreeImage/PluginDDS.cpp
            Source/FreeImage/PluginEXR.cpp
            Source/FreeImage/PluginG3.cpp
            Source/FreeImage/PluginGIF.cpp
            Source/FreeImage/PluginHDR.cpp
            Source/FreeImage/PluginICO.cpp
            Source/FreeImage/PluginIFF.cpp
            Source/FreeImage/PluginJ2K.cpp
            Source/FreeImage/PluginJNG.cpp
            Source/FreeImage/PluginJP2.cpp
            Source/FreeImage/PluginJPEG.cpp
            Source/FreeImage/PluginJXR.cpp
            Source/FreeImage/PluginKOALA.cpp
            Source/FreeImage/PluginMNG.cpp
            Source/FreeImage/PluginPCD.cpp
            Source/FreeImage/PluginPCX.cpp
            Source/FreeImage/PluginPFM.cpp
            Source/FreeImage/PluginPICT.cpp
            Source/FreeImage/PluginPNG.cpp
            Source/FreeImage/PluginPNM.cpp
            Source/FreeImage/PluginPSD.cpp
            Source/FreeImage/PluginRAS.cpp
            Source/FreeImage/PluginRAW.cpp
            Source/FreeImage/PluginSGI.cpp
            Source/FreeImage/PluginTARGA.cpp
            Source/FreeImage/PluginTIFF.cpp
            Source/FreeImage/PluginWBMP.cpp
            Source/FreeImage/PluginWebP.cpp
            Source/FreeImage/PluginXBM.cpp
            Source/FreeImage/PluginXPM.cpp
            Source/FreeImage/PSDParser.cpp
            Source/FreeImage/TIFFLogLuv.cpp
            Source/FreeImage/Conversion.cpp
            Source/FreeImage/Conversion16_555.cpp
            Source/FreeImage/Conversion16_565.cpp
            Source/FreeImage/Conversion24.cpp
            Source/FreeImage/Conversion32.cpp
            Source/FreeImage/Conversion4.cpp
            Source/FreeImage/Conversion8.cpp
            Source/FreeImage/ConversionFloat.cpp
            Source/FreeImage/ConversionRGB16.cpp
            Source/FreeImage/ConversionRGBF.cpp
            Source/FreeImage/ConversionType.cpp
            Source/FreeImage/ConversionUINT16.cpp
            Source/FreeImage/Halftoning.cpp
            Source/FreeImage/tmoColorConvert.cpp
            Source/FreeImage/tmoDrago03.cpp
            Source/FreeImage/tmoFattal02.cpp
            Source/FreeImage/tmoReinhard05.cpp
            Source/FreeImage/ToneMapping.cpp
            Source/FreeImage/NNQuantizer.cpp
            Source/FreeImage/WuQuantizer.cpp
            Source/FreeImage/CacheFile.cpp
            Source/FreeImage/MultiPage.cpp
            Source/FreeImage/ZLibInterface.cpp
            Source/Metadata/Exif.cpp
            Source/Metadata/FIRational.cpp
            Source/Metadata/FreeImageTag.cpp
            Source/Metadata/IPTC.cpp
            Source/Metadata/TagConversion.cpp
            Source/Metadata/TagLib.cpp
            Source/Metadata/XTIFF.cpp
            Source/FreeImageToolkit/Background.cpp
            Source/FreeImageToolkit/BSplineRotate.cpp
            Source/FreeImageToolkit/Channels.cpp
            Source/FreeImageToolkit/ClassicRotate.cpp
            Source/FreeImageToolkit/Colors.cpp
            Source/FreeImageToolkit/CopyPaste.cpp
            Source/FreeImageToolkit/Display.cpp
            Source/FreeImageToolkit/Flip.cpp
            Source/FreeImageToolkit/JPEGTransform.cpp
            Source/FreeImageToolkit/MultigridPoissonSolver.cpp
            Source/FreeImageToolkit/Rescale.cpp
            Source/FreeImageToolkit/Resize.cpp
            Source/LibJPEG/jaricom.c
            Source/LibJPEG/jcapimin.c
            Source/LibJPEG/jcapistd.c
            Source/LibJPEG/jcarith.c
            Source/LibJPEG/jccoefct.c
            Source/LibJPEG/jccolor.c
            Source/LibJPEG/jcdctmgr.c
            Source/LibJPEG/jchuff.c
            Source/LibJPEG/jcinit.c
            Source/LibJPEG/jcmainct.c
            Source/LibJPEG/jcmarker.c
            Source/LibJPEG/jcmaster.c
            Source/LibJPEG/jcomapi.c
            Source/LibJPEG/jcparam.c
            Source/LibJPEG/jcprepct.c
            Source/LibJPEG/jcsample.c
            Source/LibJPEG/jctrans.c
            Source/LibJPEG/jdapimin.c
            Source/LibJPEG/jdapistd.c
            Source/LibJPEG/jdarith.c
            Source/LibJPEG/jdatadst.c
            Source/LibJPEG/jdatasrc.c
            Source/LibJPEG/jdcoefct.c
            Source/LibJPEG/jdcolor.c
            Source/LibJPEG/jddctmgr.c
            Source/LibJPEG/jdhuff.c
            Source/LibJPEG/jdinput.c
            Source/LibJPEG/jdmainct.c
            Source/LibJPEG/jdmarker.c
            Source/LibJPEG/jdmaster.c
            Source/LibJPEG/jdmerge.c
            Source/LibJPEG/jdpostct.c
            Source/LibJPEG/jdsample.c
            Source/LibJPEG/jdtrans.c
            Source/LibJPEG/jerror.c
            Source/LibJPEG/jfdctflt.c
            Source/LibJPEG/jfdctfst.c
            Source/LibJPEG/jfdctint.c
            Source/LibJPEG/jidctflt.c
            Source/LibJPEG/jidctfst.c
            Source/LibJPEG/jidctint.c
            Source/LibJPEG/jmemmgr.c
            Source/LibJPEG/jmemnobs.c
            Source/LibJPEG/jquant1.c
            Source/LibJPEG/jquant2.c
            Source/LibJPEG/jutils.c
            Source/LibJPEG/transupp.c
            Source/LibPNG/png.c
            Source/LibPNG/pngerror.c
            Source/LibPNG/pngget.c
            Source/LibPNG/pngmem.c
            Source/LibPNG/pngpread.c
            Source/LibPNG/pngread.c
            Source/LibPNG/pngrio.c
            Source/LibPNG/pngrtran.c
            Source/LibPNG/pngrutil.c
            Source/LibPNG/pngset.c
            Source/LibPNG/pngtrans.c
            Source/LibPNG/pngwio.c
            Source/LibPNG/pngwrite.c
            Source/LibPNG/pngwtran.c
            Source/LibPNG/pngwutil.c
            Source/LibTIFF4/tif_aux.c
            Source/LibTIFF4/tif_close.c
            Source/LibTIFF4/tif_codec.c
            Source/LibTIFF4/tif_color.c
            Source/LibTIFF4/tif_compress.c
            Source/LibTIFF4/tif_dir.c
            Source/LibTIFF4/tif_dirinfo.c
            Source/LibTIFF4/tif_dirread.c
            Source/LibTIFF4/tif_dirwrite.c
            Source/LibTIFF4/tif_dumpmode.c
            Source/LibTIFF4/tif_error.c
            Source/LibTIFF4/tif_extension.c
            Source/LibTIFF4/tif_fax3.c
            Source/LibTIFF4/tif_fax3sm.c
            Source/LibTIFF4/tif_flush.c
            Source/LibTIFF4/tif_getimage.c
            Source/LibTIFF4/tif_jpeg.c
            Source/LibTIFF4/tif_luv.c
            Source/LibTIFF4/tif_lzma.c
            Source/LibTIFF4/tif_lzw.c
            Source/LibTIFF4/tif_next.c
            Source/LibTIFF4/tif_ojpeg.c
            Source/LibTIFF4/tif_open.c
            Source/LibTIFF4/tif_packbits.c
            Source/LibTIFF4/tif_pixarlog.c
            Source/LibTIFF4/tif_predict.c
            Source/LibTIFF4/tif_print.c
            Source/LibTIFF4/tif_read.c
            Source/LibTIFF4/tif_strip.c
            Source/LibTIFF4/tif_swab.c
            Source/LibTIFF4/tif_thunder.c
            Source/LibTIFF4/tif_tile.c
            Source/LibTIFF4/tif_version.c
            Source/LibTIFF4/tif_warning.c
            Source/LibTIFF4/tif_write.c
            Source/LibTIFF4/tif_zip.c
            Source/ZLib/adler32.c
            Source/ZLib/compress.c
            Source/ZLib/crc32.c
            Source/ZLib/deflate.c
            Source/ZLib/gzclose.c
            Source/ZLib/gzlib.c
            Source/ZLib/gzread.c
            Source/ZLib/gzwrite.c
            Source/ZLib/infback.c
            Source/ZLib/inffast.c
            Source/ZLib/inflate.c
            Source/ZLib/inftrees.c
            Source/ZLib/trees.c
            Source/ZLib/uncompr.c
            Source/ZLib/zutil.c
            Source/LibOpenJPEG/bio.c
            Source/LibOpenJPEG/cio.c
            Source/LibOpenJPEG/dwt.c
            Source/LibOpenJPEG/event.c
            Source/LibOpenJPEG/function_list.c
            Source/LibOpenJPEG/image.c
            Source/LibOpenJPEG/invert.c
            Source/LibOpenJPEG/j2k.c
            Source/LibOpenJPEG/jp2.c
            Source/LibOpenJPEG/mct.c
            Source/LibOpenJPEG/mqc.c
            Source/LibOpenJPEG/openjpeg.c
            Source/LibOpenJPEG/opj_clock.c
            Source/LibOpenJPEG/pi.c
            Source/LibOpenJPEG/raw.c
            Source/LibOpenJPEG/t1.c
            Source/LibOpenJPEG/t2.c
            Source/LibOpenJPEG/tcd.c
            Source/LibOpenJPEG/tgt.c
            Source/OpenEXR/IexMath/IexMathFpu.cpp
            Source/OpenEXR/IlmImf/b44ExpLogTable.cpp
            Source/OpenEXR/IlmImf/ImfAcesFile.cpp
            Source/OpenEXR/IlmImf/ImfAttribute.cpp
            Source/OpenEXR/IlmImf/ImfB44Compressor.cpp
            Source/OpenEXR/IlmImf/ImfBoxAttribute.cpp
            Source/OpenEXR/IlmImf/ImfChannelList.cpp
            Source/OpenEXR/IlmImf/ImfChannelListAttribute.cpp
            Source/OpenEXR/IlmImf/ImfChromaticities.cpp
            Source/OpenEXR/IlmImf/ImfChromaticitiesAttribute.cpp
            Source/OpenEXR/IlmImf/ImfCompositeDeepScanLine.cpp
            Source/OpenEXR/IlmImf/ImfCompressionAttribute.cpp
            Source/OpenEXR/IlmImf/ImfCompressor.cpp
            Source/OpenEXR/IlmImf/ImfConvert.cpp
            Source/OpenEXR/IlmImf/ImfCRgbaFile.cpp
            Source/OpenEXR/IlmImf/ImfDeepCompositing.cpp
            Source/OpenEXR/IlmImf/ImfDeepFrameBuffer.cpp
            Source/OpenEXR/IlmImf/ImfDeepImageStateAttribute.cpp
            Source/OpenEXR/IlmImf/ImfDeepScanLineInputFile.cpp
            Source/OpenEXR/IlmImf/ImfDeepScanLineInputPart.cpp
            Source/OpenEXR/IlmImf/ImfDeepScanLineOutputFile.cpp
            Source/OpenEXR/IlmImf/ImfDeepScanLineOutputPart.cpp
            Source/OpenEXR/IlmImf/ImfDeepTiledInputFile.cpp
            Source/OpenEXR/IlmImf/ImfDeepTiledInputPart.cpp
            Source/OpenEXR/IlmImf/ImfDeepTiledOutputFile.cpp
            Source/OpenEXR/IlmImf/ImfDeepTiledOutputPart.cpp
            Source/OpenEXR/IlmImf/ImfDoubleAttribute.cpp
            Source/OpenEXR/IlmImf/ImfDwaCompressor.cpp
            Source/OpenEXR/IlmImf/ImfEnvmap.cpp
            Source/OpenEXR/IlmImf/ImfEnvmapAttribute.cpp
            Source/OpenEXR/IlmImf/ImfFastHuf.cpp
            Source/OpenEXR/IlmImf/ImfFloatAttribute.cpp
            Source/OpenEXR/IlmImf/ImfFloatVectorAttribute.cpp
            Source/OpenEXR/IlmImf/ImfFrameBuffer.cpp
            Source/OpenEXR/IlmImf/ImfFramesPerSecond.cpp
            Source/OpenEXR/IlmImf/ImfGenericInputFile.cpp
            Source/OpenEXR/IlmImf/ImfGenericOutputFile.cpp
            Source/OpenEXR/IlmImf/ImfHeader.cpp
            Source/OpenEXR/IlmImf/ImfHuf.cpp
            Source/OpenEXR/IlmImf/ImfInputFile.cpp
            Source/OpenEXR/IlmImf/ImfInputPart.cpp
            Source/OpenEXR/IlmImf/ImfInputPartData.cpp
            Source/OpenEXR/IlmImf/ImfIntAttribute.cpp
            Source/OpenEXR/IlmImf/ImfIO.cpp
            Source/OpenEXR/IlmImf/ImfKeyCode.cpp
            Source/OpenEXR/IlmImf/ImfKeyCodeAttribute.cpp
            Source/OpenEXR/IlmImf/ImfLineOrderAttribute.cpp
            Source/OpenEXR/IlmImf/ImfLut.cpp
            Source/OpenEXR/IlmImf/ImfMatrixAttribute.cpp
            Source/OpenEXR/IlmImf/ImfMisc.cpp
            Source/OpenEXR/IlmImf/ImfMultiPartInputFile.cpp
            Source/OpenEXR/IlmImf/ImfMultiPartOutputFile.cpp
            Source/OpenEXR/IlmImf/ImfMultiView.cpp
            Source/OpenEXR/IlmImf/ImfOpaqueAttribute.cpp
            Source/OpenEXR/IlmImf/ImfOutputFile.cpp
            Source/OpenEXR/IlmImf/ImfOutputPart.cpp
            Source/OpenEXR/IlmImf/ImfOutputPartData.cpp
            Source/OpenEXR/IlmImf/ImfPartType.cpp
            Source/OpenEXR/IlmImf/ImfPizCompressor.cpp
            Source/OpenEXR/IlmImf/ImfPreviewImage.cpp
            Source/OpenEXR/IlmImf/ImfPreviewImageAttribute.cpp
            Source/OpenEXR/IlmImf/ImfPxr24Compressor.cpp
            Source/OpenEXR/IlmImf/ImfRational.cpp
            Source/OpenEXR/IlmImf/ImfRationalAttribute.cpp
            Source/OpenEXR/IlmImf/ImfRgbaFile.cpp
            Source/OpenEXR/IlmImf/ImfRgbaYca.cpp
            Source/OpenEXR/IlmImf/ImfRle.cpp
            Source/OpenEXR/IlmImf/ImfRleCompressor.cpp
            Source/OpenEXR/IlmImf/ImfScanLineInputFile.cpp
            Source/OpenEXR/IlmImf/ImfStandardAttributes.cpp
            Source/OpenEXR/IlmImf/ImfStdIO.cpp
            Source/OpenEXR/IlmImf/ImfStringAttribute.cpp
            Source/OpenEXR/IlmImf/ImfStringVectorAttribute.cpp
            Source/OpenEXR/IlmImf/ImfSystemSpecific.cpp
            Source/OpenEXR/IlmImf/ImfTestFile.cpp
            Source/OpenEXR/IlmImf/ImfThreading.cpp
            Source/OpenEXR/IlmImf/ImfTileDescriptionAttribute.cpp
            Source/OpenEXR/IlmImf/ImfTiledInputFile.cpp
            Source/OpenEXR/IlmImf/ImfTiledInputPart.cpp
            Source/OpenEXR/IlmImf/ImfTiledMisc.cpp
            Source/OpenEXR/IlmImf/ImfTiledOutputFile.cpp
            Source/OpenEXR/IlmImf/ImfTiledOutputPart.cpp
            Source/OpenEXR/IlmImf/ImfTiledRgbaFile.cpp
            Source/OpenEXR/IlmImf/ImfTileOffsets.cpp
            Source/OpenEXR/IlmImf/ImfTimeCode.cpp
            Source/OpenEXR/IlmImf/ImfTimeCodeAttribute.cpp
            Source/OpenEXR/IlmImf/ImfVecAttribute.cpp
            Source/OpenEXR/IlmImf/ImfVersion.cpp
            Source/OpenEXR/IlmImf/ImfWav.cpp
            Source/OpenEXR/IlmImf/ImfZip.cpp
            Source/OpenEXR/IlmImf/ImfZipCompressor.cpp
            Source/OpenEXR/Imath/ImathBox.cpp
            Source/OpenEXR/Imath/ImathColorAlgo.cpp
            Source/OpenEXR/Imath/ImathFun.cpp
            Source/OpenEXR/Imath/ImathMatrixAlgo.cpp
            Source/OpenEXR/Imath/ImathRandom.cpp
            Source/OpenEXR/Imath/ImathShear.cpp
            Source/OpenEXR/Imath/ImathVec.cpp
            Source/OpenEXR/Iex/IexBaseExc.cpp
            Source/OpenEXR/Iex/IexThrowErrnoExc.cpp
            Source/OpenEXR/Half/half.cpp
            Source/OpenEXR/IlmThread/IlmThread.cpp
            Source/OpenEXR/IlmThread/IlmThreadMutex.cpp
            Source/OpenEXR/IlmThread/IlmThreadPool.cpp
            Source/OpenEXR/IlmThread/IlmThreadSemaphore.cpp
            Source/OpenEXR/IexMath/IexMathFloatExc.cpp
            Source/LibRawLite/internal/dcraw_common.cpp
            Source/LibRawLite/internal/dcraw_fileio.cpp
            Source/LibRawLite/internal/demosaic_packs.cpp
            Source/LibRawLite/src/libraw_c_api.cpp
            Source/LibRawLite/src/libraw_cxx.cpp
            Source/LibRawLite/src/libraw_datastream.cpp
            Source/LibWebP/src/dec/alpha_dec.c
            Source/LibWebP/src/dec/buffer_dec.c
            Source/LibWebP/src/dec/frame_dec.c
            Source/LibWebP/src/dec/idec_dec.c
            Source/LibWebP/src/dec/io_dec.c
            Source/LibWebP/src/dec/quant_dec.c
            Source/LibWebP/src/dec/tree_dec.c
            Source/LibWebP/src/dec/vp8l_dec.c
            Source/LibWebP/src/dec/vp8_dec.c
            Source/LibWebP/src/dec/webp_dec.c
            Source/LibWebP/src/demux/anim_decode.c
            Source/LibWebP/src/demux/demux.c
            Source/LibWebP/src/dsp/alpha_processing.c
            Source/LibWebP/src/dsp/alpha_processing_mips_dsp_r2.c
            Source/LibWebP/src/dsp/alpha_processing_neon.c
            Source/LibWebP/src/dsp/alpha_processing_sse2.c
            Source/LibWebP/src/dsp/alpha_processing_sse41.c
            Source/LibWebP/src/dsp/cost.c
            Source/LibWebP/src/dsp/cost_mips32.c
            Source/LibWebP/src/dsp/cost_mips_dsp_r2.c
            Source/LibWebP/src/dsp/cost_sse2.c
            Source/LibWebP/src/dsp/cpu.c
            Source/LibWebP/src/dsp/dec.c
            Source/LibWebP/src/dsp/dec_clip_tables.c
            Source/LibWebP/src/dsp/dec_mips32.c
            Source/LibWebP/src/dsp/dec_mips_dsp_r2.c
            Source/LibWebP/src/dsp/dec_msa.c
            Source/LibWebP/src/dsp/dec_neon.c
            Source/LibWebP/src/dsp/dec_sse2.c
            Source/LibWebP/src/dsp/dec_sse41.c
            Source/LibWebP/src/dsp/enc.c
            Source/LibWebP/src/dsp/enc_avx2.c
            Source/LibWebP/src/dsp/enc_mips32.c
            Source/LibWebP/src/dsp/enc_mips_dsp_r2.c
            Source/LibWebP/src/dsp/enc_msa.c
            Source/LibWebP/src/dsp/enc_neon.c
            Source/LibWebP/src/dsp/enc_sse2.c
            Source/LibWebP/src/dsp/enc_sse41.c
            Source/LibWebP/src/dsp/filters.c
            Source/LibWebP/src/dsp/filters_mips_dsp_r2.c
            Source/LibWebP/src/dsp/filters_msa.c
            Source/LibWebP/src/dsp/filters_neon.c
            Source/LibWebP/src/dsp/filters_sse2.c
            Source/LibWebP/src/dsp/lossless.c
            Source/LibWebP/src/dsp/lossless_enc.c
            Source/LibWebP/src/dsp/lossless_enc_mips32.c
            Source/LibWebP/src/dsp/lossless_enc_mips_dsp_r2.c
            Source/LibWebP/src/dsp/lossless_enc_msa.c
            Source/LibWebP/src/dsp/lossless_enc_neon.c
            Source/LibWebP/src/dsp/lossless_enc_sse2.c
            Source/LibWebP/src/dsp/lossless_enc_sse41.c
            Source/LibWebP/src/dsp/lossless_mips_dsp_r2.c
            Source/LibWebP/src/dsp/lossless_msa.c
            Source/LibWebP/src/dsp/lossless_neon.c
            Source/LibWebP/src/dsp/lossless_sse2.c
            Source/LibWebP/src/dsp/rescaler.c
            Source/LibWebP/src/dsp/rescaler_mips32.c
            Source/LibWebP/src/dsp/rescaler_mips_dsp_r2.c
            Source/LibWebP/src/dsp/rescaler_msa.c
            Source/LibWebP/src/dsp/rescaler_neon.c
            Source/LibWebP/src/dsp/rescaler_sse2.c
            Source/LibWebP/src/dsp/ssim.c
            Source/LibWebP/src/dsp/ssim_sse2.c
            Source/LibWebP/src/dsp/upsampling.c
            Source/LibWebP/src/dsp/upsampling_mips_dsp_r2.c
            Source/LibWebP/src/dsp/upsampling_msa.c
            Source/LibWebP/src/dsp/upsampling_neon.c
            Source/LibWebP/src/dsp/upsampling_sse2.c
            Source/LibWebP/src/dsp/upsampling_sse41.c
            Source/LibWebP/src/dsp/yuv.c
            Source/LibWebP/src/dsp/yuv_mips32.c
            Source/LibWebP/src/dsp/yuv_mips_dsp_r2.c
            Source/LibWebP/src/dsp/yuv_neon.c
            Source/LibWebP/src/dsp/yuv_sse2.c
            Source/LibWebP/src/dsp/yuv_sse41.c
            Source/LibWebP/src/enc/alpha_enc.c
            Source/LibWebP/src/enc/analysis_enc.c
            Source/LibWebP/src/enc/backward_references_cost_enc.c
            Source/LibWebP/src/enc/backward_references_enc.c
            Source/LibWebP/src/enc/config_enc.c
            Source/LibWebP/src/enc/cost_enc.c
            Source/LibWebP/src/enc/filter_enc.c
            Source/LibWebP/src/enc/frame_enc.c
            Source/LibWebP/src/enc/histogram_enc.c
            Source/LibWebP/src/enc/iterator_enc.c
            Source/LibWebP/src/enc/near_lossless_enc.c
            Source/LibWebP/src/enc/picture_csp_enc.c
            Source/LibWebP/src/enc/picture_enc.c
            Source/LibWebP/src/enc/picture_psnr_enc.c
            Source/LibWebP/src/enc/picture_rescale_enc.c
            Source/LibWebP/src/enc/picture_tools_enc.c
            Source/LibWebP/src/enc/predictor_enc.c
            Source/LibWebP/src/enc/quant_enc.c
            Source/LibWebP/src/enc/syntax_enc.c
            Source/LibWebP/src/enc/token_enc.c
            Source/LibWebP/src/enc/tree_enc.c
            Source/LibWebP/src/enc/vp8l_enc.c
            Source/LibWebP/src/enc/webp_enc.c
            Source/LibWebP/src/mux/anim_encode.c
            Source/LibWebP/src/mux/muxedit.c
            Source/LibWebP/src/mux/muxinternal.c
            Source/LibWebP/src/mux/muxread.c
            Source/LibWebP/src/utils/bit_reader_utils.c
            Source/LibWebP/src/utils/bit_writer_utils.c
            Source/LibWebP/src/utils/color_cache_utils.c
            Source/LibWebP/src/utils/filters_utils.c
            Source/LibWebP/src/utils/huffman_encode_utils.c
            Source/LibWebP/src/utils/huffman_utils.c
            Source/LibWebP/src/utils/quant_levels_dec_utils.c
            Source/LibWebP/src/utils/quant_levels_utils.c
            Source/LibWebP/src/utils/random_utils.c
            Source/LibWebP/src/utils/rescaler_utils.c
            Source/LibWebP/src/utils/thread_utils.c
            Source/LibWebP/src/utils/utils.c
            Source/LibJXR/image/decode/decode.c
            Source/LibJXR/image/decode/JXRTranscode.c
            Source/LibJXR/image/decode/postprocess.c
            Source/LibJXR/image/decode/segdec.c
            Source/LibJXR/image/decode/strdec.c
            Source/LibJXR/image/decode/strdec_x86.c
            Source/LibJXR/image/decode/strInvTransform.c
            Source/LibJXR/image/decode/strPredQuantDec.c
            Source/LibJXR/image/encode/encode.c
            Source/LibJXR/image/encode/segenc.c
            Source/LibJXR/image/encode/strenc.c
            Source/LibJXR/image/encode/strenc_x86.c
            Source/LibJXR/image/encode/strFwdTransform.c
            Source/LibJXR/image/encode/strPredQuantEnc.c
            Source/LibJXR/image/sys/adapthuff.c
            Source/LibJXR/image/sys/image.c
            Source/LibJXR/image/sys/strcodec.c
            Source/LibJXR/image/sys/strPredQuant.c
            Source/LibJXR/image/sys/strTransform.c
            Source/LibJXR/jxrgluelib/JXRGlue.c
            Source/LibJXR/jxrgluelib/JXRGlueJxr.c
            Source/LibJXR/jxrgluelib/JXRGluePFC.c
            Source/LibJXR/jxrgluelib/JXRMeta.c
        )
        target_include_directories(freeimage PRIVATE
            Source
            Source/Metadata
            Source/FreeImageToolkit
            Source/LibJPEG
            Source/LibPNG
            Source/LibTIFF4
            Source/ZLib
            Source/LibOpenJPEG
            Source/OpenEXR
            Source/OpenEXR/Half
            Source/OpenEXR/Iex
            Source/OpenEXR/IlmImf
            Source/OpenEXR/IlmThread
            Source/OpenEXR/Imath
            Source/OpenEXR/IexMath
            Source/LibRawLite
            Source/LibRawLite/dcraw
            Source/LibRawLite/internal
            Source/LibRawLite/libraw
            Source/LibRawLite/src
            Source/LibWebP
            Source/LibJXR
            Source/LibJXR/common/include
            Source/LibJXR/image/sys
            Source/LibJXR/jxrgluelib
        )
        target_compile_definitions(freeimage PRIVATE FREEIMAGE_LIB LIBRAW_NODLL OPJ_STATIC DISABLE_PERF_MEASUREMENT)

        if(MSVC)
            target_compile_options(freeimage PRIVATE
                "/wd4789;" # disable "buffer 'identifier' of size N bytes will be overrun; M bytes will be written starting at offset L" warnings
                "/wd4311;" # disable "'variable' : pointer truncation from 'type' to 'type'" warnings
                "/wd4804;" # disable "'operation' : unsafe use of type 'bool' in operation" warnings
                "/wd4806;" # disable "'operation' : unsafe operation: no value of type 'type' promoted to type 'type' can equal the given constant" warnings
                "/wd4722;" # disable "'function' : destructor never returns, potential memory leak" warnings
            )
        endif()

        install(TARGETS freeimage
            LIBRARY DESTINATION lib
        )
        install(FILES Source/FreeImage.h
            DESTINATION include
        )
    ]=])

    FetchContent_Declare(freeimage_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/WinMerge/freeimage.git"
        GIT_TAG "master"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${SOURCE_DIR}/temp/CMakeLists.txt"
            "${SOURCE_DIR}/source/CMakeLists.txt"
    )

    FetchContent_MakeAvailable(freeimage_proj)

    # Configure
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S . -B "${SOURCE_DIR}/build"
        WORKING_DIRECTORY "${SOURCE_DIR}/source"
        RESULT_VARIABLE cmakeResult
    )

    if(cmakeResult EQUAL "1")
        message(WARNING "Failed to configure FreeImage")
    else()
        # Build
        execute_process(
            COMMAND "${CMAKE_COMMAND}" --build . --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build"
            RESULT_VARIABLE cmakeResult
        )

        if(cmakeResult EQUAL "1")
            message(WARNING "Failed to build FreeImage")
        else()
            # Install
            execute_process(
                COMMAND ${CMAKE_COMMAND} --install . --prefix "${SOURCE_DIR}" --config Release
                WORKING_DIRECTORY "${SOURCE_DIR}/build"
                RESULT_VARIABLE cmakeResult
            )

            if(cmakeResult EQUAL "1")
                message(WARNING "Failed to install FreeImage")
            else()
                find_path(FREEIMAGE_INCLUDE FreeImage.h PATHS "${TOOLCHAIN_LIBRARY_PATH}/FreeImage" PATH_SUFFIXES include)
                find_library(FREEIMAGE_LIBRARY freeimage PATHS "${TOOLCHAIN_LIBRARY_PATH}/FreeImage" PATH_SUFFIXES lib)

                add_library(freeimage::FreeImage STATIC IMPORTED)
                set_target_properties(freeimage::FreeImage PROPERTIES IMPORTED_LOCATION ${FREEIMAGE_LIBRARY})
                target_include_directories(freeimage::FreeImage INTERFACE ${FREEIMAGE_INCLUDE})
                target_compile_definitions(freeimage::FreeImage INTERFACE FREEIMAGE_LIB OPJ_STATIC DISABLE_PERF_MEASUREMENT)
            endif()
        endif()
    endif()
endif()
