package dev.aaa1115910.bv.viewmodel.home

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import dev.aaa1115910.biliapi.entity.user.DynamicItem
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.biliapi.http.entity.AuthFailureException
import dev.aaa1115910.biliapi.repositories.UserRepository
import dev.aaa1115910.bv.BVApp
import dev.aaa1115910.bv.BuildConfig
import dev.aaa1115910.bv.R
import dev.aaa1115910.bv.util.Prefs
import dev.aaa1115910.bv.util.fInfo
import dev.aaa1115910.bv.util.fWarn
import dev.aaa1115910.bv.util.toast
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.android.annotation.KoinViewModel
import dev.aaa1115910.bv.repository.UserRepository as BvUserRepository

@KoinViewModel
class DynamicViewModel(
    private val bvUserRepository: BvUserRepository,
    private val userRepository: UserRepository
) : ViewModel() {
    companion object {
        private val logger = KotlinLogging.logger {}
    }

    val dynamicVideoList = mutableStateListOf<DynamicVideo>()
    val dynamicAllList = mutableStateListOf<DynamicItem>()

    private var currentVideoPage = 0
    var loadingVideo = false
        private set
    var videoHasMore = true
        private set
    private var videoHistoryOffset: String? = null
    private var videoUpdateBaseline: String? = null

    private var currentAllPage = 0
    var loadingAll by mutableStateOf(false)
        private set
    var allHasMore by mutableStateOf(true)
        private set
    private var allHistoryOffset: String? = null
    private var allUpdateBaseline: String? = null
    
    // 添加防抖控制
    private var isVideoRequesting = false
    private var isAllRequesting = false

    val isLogin get() = bvUserRepository.isLogin

    init {
        println("=====init DynamicViewModel")
    }

    suspend fun loadMoreVideo() {
        if (loadingVideo || !videoHasMore || !bvUserRepository.isLogin || isVideoRequesting) return
        isVideoRequesting = true
        
        try {
            loadVideoData()
        } finally {
            isVideoRequesting = false
        }
    }

    suspend fun loadMoreAll() {
        if (loadingAll || !allHasMore || !bvUserRepository.isLogin || isAllRequesting) return
        isAllRequesting = true
        
        try {
            loadAllData()
        } finally {
            isAllRequesting = false
        }
    }

    private suspend fun loadVideoData() {
        loadingVideo = true
        val nextPage = currentVideoPage + 1
        logger.fInfo { "Load more dynamic videos [apiType=${Prefs.apiType}, offset=$videoHistoryOffset, page=$nextPage]" }
        
        try {
            val dynamicVideoData = userRepository.getDynamicVideos(
                page = nextPage,
                offset = videoHistoryOffset ?: "",
                updateBaseline = videoUpdateBaseline ?: "",
                preferApiType = Prefs.apiType
            )
            
            // 在主线程更新UI和状态
            withContext(Dispatchers.Main) {
                dynamicVideoList.addAll(dynamicVideoData.videos)
                videoHistoryOffset = dynamicVideoData.historyOffset
                videoUpdateBaseline = dynamicVideoData.updateBaseline
                videoHasMore = dynamicVideoData.hasMore
                currentVideoPage = nextPage
                loadingVideo = false
            }
            
            logger.fInfo { "Load dynamic video list page: ${nextPage}, size: ${dynamicVideoData.videos.size}" }
            
        } catch (e: Exception) {
            logger.fWarn { "Load dynamic video list failed: ${e.stackTraceToString()}" }
            
            withContext(Dispatchers.Main) {
                loadingVideo = false
            }
            
            when (e) {
                is AuthFailureException -> {
                    withContext(Dispatchers.Main) {
                        BVApp.context.getString(R.string.exception_auth_failure)
                            .toast(BVApp.context)
                    }
                    logger.fInfo { "User auth failure" }
                    if (!BuildConfig.DEBUG) bvUserRepository.logout()
                }
                else -> {
                    withContext(Dispatchers.Main) {
                        "加载动态失败: ${e.localizedMessage}".toast(BVApp.context)
                    }
                }
            }
        }
    }

    private suspend fun loadAllData() {
        loadingAll = true
        val nextPage = currentAllPage + 1
        logger.fInfo { "Load more dynamic all [apiType=${Prefs.apiType}, offset=$allHistoryOffset, page=$nextPage]" }
        
        try {
            val dynamicData = userRepository.getDynamics(
                page = nextPage,
                offset = allHistoryOffset ?: "",
                updateBaseline = allUpdateBaseline ?: "",
                preferApiType = Prefs.apiType
            )
            
            withContext(Dispatchers.Main) {
                dynamicAllList.addAll(dynamicData.dynamics)
                allHistoryOffset = dynamicData.historyOffset
                allUpdateBaseline = dynamicData.updateBaseline
                allHasMore = dynamicData.hasMore
                currentAllPage = nextPage
                loadingAll = false
            }
            
            logger.fInfo { "Load dynamic all list page: ${nextPage}, size: ${dynamicData.dynamics.size}" }
            
        } catch (e: Exception) {
            logger.fWarn { "Load dynamic all list failed: ${e.stackTraceToString()}" }
            
            withContext(Dispatchers.Main) {
                loadingAll = false
            }
            
            when (e) {
                is AuthFailureException -> {
                    withContext(Dispatchers.Main) {
                        BVApp.context.getString(R.string.exception_auth_failure)
                            .toast(BVApp.context)
                    }
                    logger.fInfo { "User auth failure" }
                }
                else -> {
                    withContext(Dispatchers.Main) {
                        "加载动态失败: ${e.localizedMessage}".toast(BVApp.context)
                    }
                }
            }
        }
    }

    fun clearVideoData() {
        dynamicVideoList.clear()
        currentVideoPage = 0
        loadingVideo = false
        videoHasMore = true
        videoHistoryOffset = null
        isVideoRequesting = false
    }

    fun clearAllData() {
        dynamicAllList.clear()
        currentAllPage = 0
        loadingAll = false
        allHasMore = true
        allHistoryOffset = null
        isAllRequesting = false
    }
}