package dev.aaa1115910.bv.viewmodel.home

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import dev.aaa1115910.biliapi.entity.rank.PopularVideoPage
import dev.aaa1115910.biliapi.entity.ugc.UgcItem
import dev.aaa1115910.biliapi.repositories.RecommendVideoRepository
import dev.aaa1115910.bv.BVApp
import dev.aaa1115910.bv.util.Prefs
import dev.aaa1115910.bv.util.addAllWithMainContext
import dev.aaa1115910.bv.util.toast
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.koin.android.annotation.KoinViewModel

@KoinViewModel
class PopularViewModel(
    private val recommendVideoRepository: RecommendVideoRepository
) : ViewModel() {
    // TV端核心列表
    val popularVideoList = mutableStateListOf<UgcItem>()

    // 分页状态
    private var nextPage = PopularVideoPage()
    
    // 加载状态：private set 防止多线程乱改
    var loading by mutableStateOf(false)
        private set
    var hasMore by mutableStateOf(true)
        private set
        
    // 刷新状态（保留用于可能的刷新功能）
    var refreshing by mutableStateOf(false)
        private set

    // TV端核心加载方法（优化后）
    suspend fun loadMore() {
        if (!loading && hasMore) {
            loadData()
        }
    }

    // mobile端兼容：保留旧加载方法（转发到新方法）
    suspend fun loadMore(
        beforeAppendData: () -> Unit = {}
    ) {
        if (!loading && hasMore) {
            loadDataWithCallback(beforeAppendData)
        }
    }

    private suspend fun loadData() {
        loading = true
        // 最多重试2次，解决单次网络波动
        repeat(2) { retryCount ->
            runCatching {
                val popularVideoData = recommendVideoRepository.getPopularVideos(
                    page = nextPage,
                    preferApiType = Prefs.apiType
                )
                
                // 成功加载：更新状态并退出重试
                val newItems = popularVideoData.list
                if (newItems.isNotEmpty()) {
                    popularVideoList.addAllWithMainContext(newItems)
                    nextPage = popularVideoData.nextPage
                    // 假设热门视频总是有更多数据，但如果返回为空则认为没有更多
                    hasMore = true
                } else {
                    // 返回空列表，认为没有更多数据
                    hasMore = false
                }
                return@repeat
            }.onFailure { e ->
                // 最后一次重试失败才提示
                if (retryCount == 1) {
                    withContext(Dispatchers.Main) {
                        "加载热门视频失败: ${e.localizedMessage ?: "未知错误"}"
                            .toast(BVApp.context)
                    }
                } else {
                    delay(800) // 缩短重试间隔
                }
            }
        }
        loading = false
    }

    // mobile端兼容：保留带回调的加载方法
    private suspend fun loadDataWithCallback(
        beforeAppendData: () -> Unit = {}
    ) {
        loading = true
        // 最多重试2次
        repeat(2) { retryCount ->
            runCatching {
                val popularVideoData = recommendVideoRepository.getPopularVideos(
                    page = nextPage,
                    preferApiType = Prefs.apiType
                )
                
                beforeAppendData()
                val newItems = popularVideoData.list
                if (newItems.isNotEmpty()) {
                    popularVideoList.addAllWithMainContext(newItems)
                    nextPage = popularVideoData.nextPage
                    hasMore = true
                } else {
                    hasMore = false
                }
                return@repeat
            }.onFailure { e ->
                if (retryCount == 1) {
                    withContext(Dispatchers.Main) {
                        "加载热门视频失败: ${e.localizedMessage ?: "未知错误"}"
                            .toast(BVApp.context)
                    }
                } else {
                    delay(800)
                }
            }
        }
        loading = false
    }

    // TV端核心清空方法（优化后）
    fun clearData() {
        popularVideoList.clear()
        resetPage()
        loading = false
        hasMore = true
    }

    // 重置分页（用于刷新）
    fun resetPage() {
        nextPage = PopularVideoPage()
        refreshing = true
    }

    // 完成刷新
    fun finishRefreshing() {
        refreshing = false
    }
}