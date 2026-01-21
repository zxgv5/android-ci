package dev.aaa1115910.bv.viewmodel.home

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import dev.aaa1115910.biliapi.entity.home.RecommendPage
import dev.aaa1115910.biliapi.entity.ugc.UgcItem
import dev.aaa1115910.biliapi.repositories.RecommendVideoRepository
import dev.aaa1115910.bv.BVApp
import dev.aaa1115910.bv.util.Prefs
import dev.aaa1115910.bv.util.addAllWithMainContext
import dev.aaa1115910.bv.util.fError
import dev.aaa1115910.bv.util.fInfo
import dev.aaa1115910.bv.util.toast
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.android.annotation.KoinViewModel

@KoinViewModel
class RecommendViewModel(
    private val recommendVideoRepository: RecommendVideoRepository
) : ViewModel() {
    private val logger = KotlinLogging.logger {}
    val recommendVideoList = mutableStateListOf<UgcItem>()

    private var nextPage = RecommendPage()
    var refreshing by mutableStateOf(true)
    var loading by mutableStateOf(false)
    var hasMore by mutableStateOf(true) // 添加hasMore状态

    suspend fun loadMore(
        beforeAppendData: () -> Unit = {}
    ) {
        var loadCount = 0
        val maxLoadMoreCount = 3
        if (!loading && hasMore) { // 添加hasMore检查
            if (recommendVideoList.size == 0) {
                // first load data
                while (recommendVideoList.size < 24 && loadCount < maxLoadMoreCount && hasMore) {
                    val emptyFun: () -> Unit = {}
                    loadData(beforeAppendData = if (loadCount == 0) beforeAppendData else emptyFun)
                    if (loadCount != 0) logger.fInfo { "Load more recommend videos because items too less" }
                    loadCount++
                }
            } else {
                val emptyFun: () -> Unit = {}
                loadData(beforeAppendData = if (loadCount == 0) beforeAppendData else emptyFun)
            }
        }
    }

    private suspend fun loadData(
        beforeAppendData: () -> Unit
    ) {
        loading = true
        logger.fInfo { "Load more recommend videos" }
        runCatching {
            val recommendData = recommendVideoRepository.getRecommendVideos(
                page = nextPage,
                preferApiType = Prefs.apiType
            )
            beforeAppendData()
            
            // 获取新数据
            val newItems = recommendData.items
            
            // 如果没有获取到新数据，则认为没有更多了
            if (newItems.isEmpty()) {
                hasMore = false
            } else {
                // 更新下一页参数
                nextPage = recommendData.nextPage
                recommendVideoList.addAllWithMainContext(newItems)
            }
        }.onFailure {
            logger.fError { "Load recommend video list failed: ${it.stackTraceToString()}" }
            withContext(Dispatchers.Main) {
                "加载推荐视频失败: ${it.localizedMessage}".toast(BVApp.context)
            }
        }
        loading = false
    }

    fun clearData() {
        recommendVideoList.clear()
        resetPage()
        loading = false
    }

    fun resetPage() {
        nextPage = RecommendPage()
        refreshing = true
        hasMore = true // 重置hasMore状态
    }
}