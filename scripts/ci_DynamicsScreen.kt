package dev.aaa1115910.bv.tv.screens.main.home

import android.content.Intent
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.bv.tv.component.LoadingTip
import dev.aaa1115910.bv.entity.carddata.VideoCardData
import dev.aaa1115910.bv.entity.proxy.ProxyArea
import dev.aaa1115910.bv.tv.R
import dev.aaa1115910.bv.tv.activities.user.FollowActivity
import dev.aaa1115910.bv.tv.activities.video.UpInfoActivity
import dev.aaa1115910.bv.tv.activities.video.VideoInfoActivity
import dev.aaa1115910.bv.tv.component.videocard.SmallVideoCard
import dev.aaa1115910.bv.tv.util.ProvideListBringIntoViewSpec
import dev.aaa1115910.bv.viewmodel.home.DynamicViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var currentFocusedIndex by remember { mutableIntStateOf(-1) }
    val gridColumns = 4

    // 完善加载条件：避免无更多数据时重复加载
    val shouldLoadMore by remember {
        derivedStateOf {
            dynamicViewModel.dynamicVideoList.isNotEmpty() &&
            currentFocusedIndex >= 0 &&
            currentFocusedIndex + 8 >= dynamicViewModel.dynamicVideoList.size &&
            dynamicViewModel.videoHasMore &&
            !dynamicViewModel.loadingVideo
        }
    }

    val showTip by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0 }
    }

    val onClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        VideoInfoActivity.actionStart(
            context = context,
            aid = dynamic.aid,
            proxyArea = ProxyArea.checkProxyArea(dynamic.title)
        )
    }

    val onLongClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        UpInfoActivity.actionStart(
            context,
            mid = dynamic.authorId,
            name = dynamic.author,
            face = dynamic.authorFace
        )
    }

    // 加载更多逻辑
    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) {
            scope.launch(Dispatchers.IO) {
                dynamicViewModel.loadMoreVideo()
            }
        }
    }

    // 焦点索引防越界
    LaunchedEffect(currentFocusedIndex, dynamicViewModel.dynamicVideoList.size) {
        if (dynamicViewModel.dynamicVideoList.isNotEmpty()) {
            currentFocusedIndex = currentFocusedIndex.coerceIn(0, dynamicViewModel.dynamicVideoList.size - 1)
        } else if (currentFocusedIndex != -1) {
            currentFocusedIndex = -1
        }
    }

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)

        if (showTip) {
            Text(
                modifier = Modifier.fillMaxWidth().offset(x = (-20).dp, y = (-8).dp),
                text = stringResource(R.string.entry_follow_screen),
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                fontSize = 12.sp,
                textAlign = TextAlign.End
            )
        }

        ProvideListBringIntoViewSpec {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .focusable()
                    .onFocusChanged {
                        if (it.isFocused && dynamicViewModel.dynamicVideoList.isNotEmpty()) {
                            // 聚焦时确保焦点在有效范围
                            currentFocusedIndex = currentFocusedIndex.coerceIn(0, dynamicViewModel.dynamicVideoList.size - 1)
                        } else if (!it.isFocused) {
                            currentFocusedIndex = -1
                        }
                    }
                    .onPreviewKeyEvent { event ->
                        // 菜单键跳转逻辑
                        if (event.type == KeyEventType.KeyUp && event.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }

                        // 方向键边界控制
                        if (event.type == KeyEventType.KeyDown && currentFocusedIndex >= 0) {
                            when (event.key) {
                                Key.DirectionLeft -> {
                                    // 第一列拦截，避免跳向侧边栏
                                    if (currentFocusedIndex % gridColumns == 0) return@onPreviewKeyEvent true
                                }
                                Key.DirectionUp -> {
                                    // 第一行拦截，阻止离开页面
                                    if (currentFocusedIndex < gridColumns) return@onPreviewKeyEvent true
                                }
                                Key.DirectionDown -> {
                                    val nextRowIndex = currentFocusedIndex + gridColumns
                                    val isLastRow = nextRowIndex >= dynamicViewModel.dynamicVideoList.size
                                    if (isLastRow) {
                                        // 最后一行：无更多数据则拦截，有数据则允许（焦点会暂时无法移动，等待加载）
                                        if (!dynamicViewModel.videoHasMore) return@onPreviewKeyEvent true
                                        // 否则允许焦点尝试移动，但由于索引无效，焦点会停留在当前位置
                                    }
                                }
                                Key.DirectionRight -> {
                                    // 最后一列拦截
                                    if (currentFocusedIndex % gridColumns == gridColumns - 1) return@onPreviewKeyEvent true
                                }
                                else -> {}
                            }
                        }

                        false
                    }
            ) {
                LazyVerticalGrid(
                    modifier = Modifier.fillMaxSize(),
                    columns = GridCells.Fixed(gridColumns),
                    state = lazyGridState,
                    contentPadding = PaddingValues(padding),
                    verticalArrangement = Arrangement.spacedBy(spacedBy),
                    horizontalArrangement = Arrangement.spacedBy(spacedBy)
                ) {
                    itemsIndexed(dynamicViewModel.dynamicVideoList) { index, item ->
                        SmallVideoCard(
                            data = remember(item.aid) {
                                VideoCardData(
                                    avid = item.aid,
                                    title = item.title,
                                    cover = item.cover,
                                    play = item.play,
                                    danmaku = item.danmaku,
                                    upName = item.author,
                                    time = item.duration * 1000L,
                                    pubTime = item.pubTime,
                                    isChargingArc = item.isChargingArc,
                                    badgeText = item.chargingArcBadge
                                )
                            },
                            onClick = { onClickVideo(item) },
                            onLongClick = { onLongClickVideo(item) },
                            onFocus = { 
                                // 安全设置焦点索引，确保不会超出列表范围
                                if (index < dynamicViewModel.dynamicVideoList.size) {
                                    currentFocusedIndex = index 
                                } else if (dynamicViewModel.dynamicVideoList.isNotEmpty()) {
                                    // 如果索引无效，将焦点设置到最后一个有效项
                                    currentFocusedIndex = dynamicViewModel.dynamicVideoList.size - 1
                                }
                            },
                            isFocused = currentFocusedIndex == index
                        )
                    }

                    // 加载提示
                    if (dynamicViewModel.loadingVideo) {
                        item(span = { GridItemSpan(maxLineSpan) }) {
                            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                LoadingTip()
                            }
                        }
                    }

                    // 保留硬编码字符串
                    if (!dynamicViewModel.videoHasMore && dynamicViewModel.dynamicVideoList.isNotEmpty()) {
                        item(span = { GridItemSpan(maxLineSpan) }) {
                            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Text(
                                    text = "没有更多了捏",
                                    color = Color.White
                                )
                            }
                        }
                    }
                }
            }
        }
    } else {
        // 保留硬编码字符串
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(text = "请先登录")
        }
    }
}